#import "MercurialDiffButtonDelegate.h"
#import "BubbleFactory.h"
#import "RepoHelper.h"

@implementation MercurialDiffButtonDelegate

- initWithTitle: (NSString *)s mainController: (MainController *)mcc hgPath: (char *)hgPath repository: (NSString *)rep {
	hg = hgPath;
	self = [super initWithTitle: s mainController: mcc repository: rep];
	[self fire: nil];
	return self;
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	NSTask *t = [[[NSTask alloc] init] autorelease];
	NSString *lp = [NSString stringWithFormat: @"%s", hg];
	[t setLaunchPath: lp];
	[t setCurrentDirectoryPath: repository];
	[t setArguments: args];

	return t;
}

- (void) upstreamUpdate: (id) sender {
	[sender setEnabled: NO];

	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"pull", nil]];

	// We do not care about the return value, really. Except that errors should be handled.
	[tq addTask: t withCallback: ^(NSArray *resultarr){
		[NSApp hide: self];
		[mc->commitWindow close];
		[sender setEnabled: YES];
		[self fire: nil];
	}];
}

- (void) pull: (id) menuItem {
	[mc->commitWindow setTitle: repository];
	[mc->commitWindow makeFirstResponder: mc->tv];

	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"in", @"--template", @"{node|short} {desc}\n", nil]];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		[mc->butt setTitle: @"Update from upstream"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(upstreamUpdate:)];
	
		NSString *string = [resultarr componentsJoinedByString: @"\n"];
		[mc->tv setString: string];
		[mc->tv setEditable: NO];
			
		NSArray *arr = [NSArray arrayWithObjects: @"in", @"-p", nil];
		NSTask *t2 = [self taskFromArguments: arr];
		[tq addTask: t2 withCallback: ^(NSArray *resultarr) {
			NSString *string2 = [resultarr componentsJoinedByString: @"\n"];
			[mc->diffView setString: string2];
			[mc->diffView setEditable: NO];
		
			[mc->commitWindow center];
			[NSApp activateIgnoringOtherApps: YES];
			[mc->commitWindow makeKeyAndOrderFront: NSApp];
		}];
	}];
}

- (void) addAll: (id) button {
	int i;
	for (i = 0; i < [currentUntracked count]; i++) {
		NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"add", [currentUntracked objectAtIndex: i], nil]];
		[tq addTask: t withCallback: nil];
	}
	[mc->untrackedWindow close];
	[self fire: nil];
}

- (void) ignoreAll: (id) button {
	NSString *path = [NSString stringWithFormat: @"%@/%@", repository, @".hgignore"];
	NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath: path];
	if (fh == nil) {
		[@".hgignore\n" writeToFile: path atomically: NO encoding: NSASCIIStringEncoding error: nil];
		fh = [NSFileHandle fileHandleForWritingAtPath: path];
		if (fh == nil)
			return;
	}
	[fh truncateFileAtOffset: [fh seekToEndOfFile]];
	int i;
	for (i = 0; i < [currentUntracked count]; i++) {
		NSString *fileName = [currentUntracked objectAtIndex: i];
		[fh writeData: [fileName dataUsingEncoding: NSUTF8StringEncoding]];
		[fh writeData: [@"\n" dataUsingEncoding: NSASCIIStringEncoding]];
	}
	[fh synchronizeFile];
	[fh closeFile];
	[mc->untrackedWindow close];
	[self fire: nil];
}

- (void)getUntrackedWithCallback: (void (^)(NSArray *))callback {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"status", @"-u", nil]];
	[tq addTask: t withCallback: ^(NSArray *arr) {
		NSMutableArray *arrmut = [NSMutableArray arrayWithArray: arr];
		int i;
		for (i = 0; i < [arrmut count]; i++) {
			NSMutableString *original = [NSMutableString stringWithString: [arrmut objectAtIndex: i]];
			if ([original characterAtIndex: 0] == '?' && [original characterAtIndex: 1] == ' ') {
				[original deleteCharactersInRange: NSMakeRange(0, 2)];
			}
			if ([original characterAtIndex: 0] == '"' && [original characterAtIndex: [original length] - 1] == '"') {
				[original deleteCharactersInRange: NSMakeRange(0, 1)];
				[original deleteCharactersInRange: NSMakeRange([original length] - 1, 1)];
			}
			[arrmut replaceObjectAtIndex: i withObject: original];
			(callback)(arrmut);
		}
	}];
}

- (void) beep: (id) something {
}

- (void) commit: (id) something {
	if (!localMod)
		return;
		
	[super commit: something];
	
	[mc->tv setString: @""];
	[mc->tv setNeedsDisplay: YES];
	if (localMod) {	
		[mc->tv setString: @""];

		// Insert text is the only method that is documented to take an attributed string.
		[mc->diffView insertText: localDiff];
		[mc->diffView scrollRangeToVisible: NSMakeRange(0, 0)];
		[mc->butt setTitle: @"Do Commit"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(clickUpdate:)];
	} else if (upstreamMod) {
		NSArray *arr = [NSArray arrayWithObjects: @"log", @"HEAD..origin", @"--abbrev-commit", @"--pretty=%h %an %s", nil];
		NSTask *t = [self taskFromArguments: arr];
		[tq addTask: t withCallback: ^(NSArray *resultarr) {
			[mc->butt setTitle: @"Update from upstream"];
			[mc->butt setTarget: self];
			[mc->butt setAction: @selector(upstreamUpdate:)];
			NSString *string = [resultarr componentsJoinedByString: @"\n"];
			[mc->tv insertText: string];
			[mc->tv setEditable: NO];
		}];
	}
	[mc->commitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->commitWindow makeKeyAndOrderFront: NSApp];
	[mc->commitWindow makeFirstResponder: mc->tv];
}

- (void) clickUpdate: (id) button {
	[NSApp hide: self];
	[mc->commitWindow close];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"commit", @"-m", [[mc->tv textStorage] mutableString], nil]];
		[tq addTask: t withCallback: ^(NSArray *resultarr) {
			[self fire: nil];
		}];
	});
}

- (void) setAllTitles: (NSString *)s {
	[s retain];
	dispatch_async(dispatch_get_main_queue(), ^{
		[s autorelease];
		[self setTitle: s];
		[self setShortTitle: s];
	});
}

- (NSString *) diffStatOfTask: (NSTask *)t {
	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
	
	NSTask *t2 = [[[NSTask alloc] init] autorelease];
	[t2 setLaunchPath: @"/usr/bin/diffstat"];
	[t2 setStandardInput: pipe];
	
	NSPipe *pipe2 = [NSPipe pipe];
	[t2 setStandardOutput: pipe2];
	
	NSFileHandle *file = [pipe2 fileHandleForReading];
	
	[t launch];
	[t2 launch];
	NSData *data = [file readDataToEndOfFile];
	[file closeFile];
	NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSString *utf8String = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	NSString *string = [utf8String stringByTrimmingCharactersInSet: cs];

	return string;
}

- (NSString *) lastGoodComponentOfString: (NSString *)s {
	NSArray *arr = [s componentsSeparatedByString: @"\n"];
	NSString *s2 = [arr objectAtIndex: [arr count] - 1];
	s2 = [s2 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	return s2;
}

- (void) setupUpstream {
	NSArray *arr = [NSArray arrayWithObjects: @"showconfig", @"paths.default", nil];
	NSTask *t = [self taskFromArguments: arr];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		if ([resultarr count]) {
			upstreamName = [resultarr objectAtIndex: 0];
			[upstreamName retain];
		} else {
			upstreamName = nil;
		}
	}];
}

- (void) checkLocal: (NSTimer *)ti {
	if (!dirty) {
		[super checkLocal: ti];
		return;
	}
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"diff", nil]];
	NSString *localChanges = [self lastGoodComponentOfString: [self diffStatOfTask: t]];
	if (![localChanges isEqual: @"0 files changed"]) {
		[self setLocalMod: YES];
		[localDiffSummary autorelease];
		localDiffSummary = [RepoHelper shortenDiff: localChanges];
		[localDiffSummary retain];
		
		NSArray *arr = [NSArray arrayWithObjects: @"diff", nil];
		NSTask *t = [self taskFromArguments: arr];
		[tq addTask: t withCallback: ^(NSArray *resultarr) {
			[localDiff autorelease];
			localDiff = [RepoHelper colorizedDiffFromArray: resultarr];
			[localDiff retain];
			[super checkLocal: ti];
			[self realFire];			
		}];
		NSString *sTit = [NSString stringWithFormat: @"%@: %@", [RepoHelper makeNameFromRepo: self], localDiffSummary];
		[self setAllTitles: sTit];
	} else {
		[self setLocalMod: NO];
		[super checkLocal: ti];
		[self realFire];
		[self setDirty: NO];
	}
}

@end