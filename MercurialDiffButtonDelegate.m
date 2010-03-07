#import "MercurialDiffButtonDelegate.h"
#import "BubbleFactory.h"

@implementation MercurialDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc hgPath: (char *)hgPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc repository: rep];
	hg = hgPath;
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
	[self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"pull", nil] withName: @"hg::pull"];
	[NSApp hide: self];
	[mc->commitWindow close];
	[sender setEnabled: YES];
	[self fire: nil];
}

- (void) pull: (id) menuItem {
	[mc->commitWindow setTitle: repository];
	[mc->commitWindow makeFirstResponder: mc->tv];

	NSArray *resultarr = [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"in", @"--template", @"{node|short} {desc}\n", nil]
			withName: @"hg::in::add"];

	[mc->butt setTitle: @"Update from upstream"];
	[mc->butt setTarget: self];
	[mc->butt setAction: @selector(upstreamUpdate:)];

	NSString *string = [resultarr componentsJoinedByString: @"\n"];
	[mc->tv setString: string];
	[mc->tv setEditable: NO];
		
	NSArray *arr = [NSArray arrayWithObjects: @"in", @"-p", nil];
	resultarr = [self arrayFromResultOfArgs: arr withName: @"hg::pull::diff"];
	string = [resultarr componentsJoinedByString: @"\n"];
	[mc->diffView setString: string];
	[mc->diffView setEditable: NO];

	[mc->commitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->commitWindow makeKeyAndOrderFront: NSApp];
}

- (void) addAll: (id) button {
	int i;
	for (i = 0; i < [currentUntracked count]; i++) {
		[self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"add", [currentUntracked objectAtIndex: i], nil] withName: @"hg::addAll::add"];
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

- (NSArray *)getUntracked {
	NSArray *arr = [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"status", @"-u", nil] withName: @"Mercurial::getUntracked::status"];
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
	}
	return arrmut;
}


- (void) beep: (id) something {
}

- (void) commit: (id) something {
	[mc->commitWindow setTitle: repository];
	[mc->commitWindow makeFirstResponder: mc->tv];

	[mc->tv setString: @""];
	[mc->tv setNeedsDisplay: YES];
	if (localMod) {	
		NSString *diffString = [self getDiff];
		[mc->tv setString: @""];
		[mc->diffView setString: diffString];
		[mc->butt setTitle: @"Do Commit"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(clickUpdate:)];
	} else if (upstreamMod) {
		NSLog(@"Here!");
		NSArray *arr = [NSArray arrayWithObjects: @"log", @"HEAD..origin", @"--abbrev-commit", @"--pretty=%h %an %s", nil];
		NSArray *resultarr = [self arrayFromResultOfArgs: arr withName: @"hg::commit::log"];
		
		[mc->butt setTitle: @"Update from upstream"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(upstreamUpdate:)];
		NSString *string = [resultarr componentsJoinedByString: @"\n"];
		[mc->tv insertText: string];
		[mc->tv setEditable: NO];
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
		[self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"commit", @"-m", [[mc->tv textStorage] mutableString], nil] withName: @"hg::clickUpdate::commit"];
		[self fire: nil];
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

- (void) handleUntracked {
	NSArray *untracked = [self getUntracked];
	if (untracked && [untracked count]) {
		untrackedFiles = YES;
		NSString *s = [NSString stringWithFormat: @"%@: %d untracked files", [repository lastPathComponent], [untracked count]];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setTitle: s];
			[self setShortTitle: s];
			[menuItem setHidden: NO];
		});
	} else {
		untrackedFiles = NO;	
	}	
}

- (void) handleLocalForMenu: (NSMenu *)m {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"diff", nil]];
	NSString *localChanges = [self lastGoodComponentOfString: [self diffStatOfTask: t]];
	if (![localChanges isEqual: @"0 files changed"]) {
		localMod = YES;
		[[m insertItemWithTitle: @"Commit these changes" action: @selector(commit:) keyEquivalent: @"" atIndex: [m numberOfItems]] setTarget: self];
		NSString *sTit = [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], [self shortenDiff: localChanges]];
		[self setAllTitles: sTit];
	} else {
		localMod = NO;
	}	
}

- (void) handleRemoteForMenu: (NSMenu *)m {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"incoming", @"-p", nil]];
	NSString *remoteDiffSt = [self diffStatOfTask: t];
	
	NSString *s2 = [self lastGoodComponentOfString: remoteDiffSt];
	if (![s2 isEqual: @"0 files changed"]) {
		upstreamMod = YES;
		[[m insertItemWithTitle: @"Update From Origin" action: @selector(pull:) keyEquivalent: @"" atIndex: [m numberOfItems]] setTarget: self];
		NSString *sTit = [NSString stringWithFormat: @"%@: %@",
			[repository lastPathComponent],
			[self shortenDiff: [s2 stringByTrimmingCharactersInSet:
				[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self setTitle: sTit];
			[self setShortTitle: sTit];
			[menuItem setHidden: NO];
		});
	} else {
		upstreamMod = NO;
	}
}

- (void) handleLogsForMenu: (NSMenu *)m {
	int i;

	NSArray *logs = [self
		arrayFromResultOfArgs: [NSArray arrayWithObjects: @"log", @"-l", @"10", @"--template", @"{node|short} {date|age} {desc}\n", nil]
		withName: @"Mercurial::fire::logs"];
	NSFont *firstFont = [NSFont userFixedPitchFontOfSize: 16.0];
	NSFont *secondFont = [NSFont userFixedPitchFontOfSize: 12.0];
	NSMenuItem *mi;
	if ([logs count] == 0) {
		mi = [[NSMenuItem alloc] initWithTitle: @"No history for this project" action: nil keyEquivalent: @""];
		[m addItem: mi];
	} else {
		for (i = 0; i < [logs count]; i++) {
			NSString *tmp = [logs objectAtIndex: i];

			NSDictionary *attributes;
			if (i == 0) {
				attributes = [NSDictionary dictionaryWithObject: firstFont forKey: NSFontAttributeName];
			} else {
				attributes = [NSDictionary dictionaryWithObject: secondFont forKey: NSFontAttributeName];
			}
			NSAttributedString *attr = [[[NSAttributedString alloc] initWithString: tmp attributes: attributes] autorelease];
			if (tmp && [tmp length] > 0) {
				mi = [[NSMenuItem alloc] initWithTitle: tmp action: nil keyEquivalent: @""];
				[mi autorelease];
				[mi setAttributedTitle: attr];
				[m addItem: mi];
			}
		}
	}
}

- (void) realFire {
	NSMenu *m = [[NSMenu alloc] initWithTitle: @"Testing"];	

	[self handleLogsForMenu: m];
	[m insertItem: [NSMenuItem separatorItem] atIndex: [m numberOfItems]];
	[self handleUntracked];
	[self handleLocalForMenu: m];
	[self handleRemoteForMenu: m];
	
	if (!untrackedFiles && !localMod && !upstreamMod)
		[self setAllTitles: [NSString stringWithFormat: @"%@", [repository lastPathComponent]]];
		
	[[m insertItemWithTitle: @"Open in Finder" action: @selector(openInFinder:) keyEquivalent: @"" atIndex: [m numberOfItems]] setTarget: self];
	[[m insertItemWithTitle: @"Open in Terminal" action: @selector(openInTerminal:) keyEquivalent: @"" atIndex: [m numberOfItems]] setTarget: self];
	[[m insertItemWithTitle: @"Ignore" action: @selector(ignore:) keyEquivalent: @"" atIndex: [m numberOfItems]] setTarget: self];

	dispatch_async(dispatch_get_main_queue(), ^{
		if (localMod)
			[menuItem setOffStateImage: [BubbleFactory getRedOfSize: 15]];
		else if (upstreamMod)
			[menuItem setOffStateImage: [BubbleFactory getYellowOfSize: 15]];
		else
			[menuItem setOffStateImage: [BubbleFactory getGreenOfSize: 15]];
		[menuItem setSubmenu: m];
		[self setupTimer];
	});
}

@end