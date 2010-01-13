#import "MercurialDiffButtonDelegate.h"

@implementation MercurialDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc hgPath: (char *)hgPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc repository: rep];
	hg = hgPath;
	[self fire: nil];
	return self;
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	NSTask *t = [[NSTask alloc] init];
	NSString *lp = [NSString stringWithFormat: @"%s", hg];
	[t setLaunchPath: lp];
	[t setCurrentDirectoryPath: repository];
	[t setArguments: args];

	return t;
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
	NSLog(@"Mercurial untracked: %@", arrmut);
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
		NSArray *arr = [NSArray arrayWithObjects: @"log", @"HEAD..origin", @"--abbrev-commit", @"--pretty=%h %an %s", nil];
		NSArray *resultarr = [self arrayFromResultOfArgs: arr withName: @"hg::commit::log"];
		
		[mc->butt setTitle: @"Update from upstream"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(upstreamUpdate:)];
		NSString *string = [resultarr objectAtIndex: 0];
		[mc->tv insertText: string];
		[mc->tv setEditable: NO];
	}
	[mc->commitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->commitWindow makeKeyAndOrderFront: NSApp];
	[mc->commitWindow makeFirstResponder: mc->tv];
}

- (void) clickUpdate: (id) button {
	[self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"commit", @"-m", [[mc->tv textStorage] mutableString], nil] withName: @"hg::clickUpdate::commit"];
	[NSApp hide: self];
	[mc->commitWindow close];
	[self fire: nil];
}

- (void) setAllTitles: (NSString *)s {
	[s retain];
	dispatch_async(dispatch_get_main_queue(), ^{
		[s autorelease];
		[self setTitle: s];
		[self setShortTitle: s];
	});
}

- (void) realFire {
	NSTask *t = [[NSTask alloc] init];
	NSString *lp = [NSString stringWithFormat: @"%s", hg];
	[t setLaunchPath: lp];
	[t setCurrentDirectoryPath: repository];
	[t setArguments: [NSArray arrayWithObjects: @"diff", nil]];

	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
	
	NSTask *t2 = [[NSTask alloc] init];
	[t2 setLaunchPath: @"/usr/bin/diffstat"];
	[t2 setStandardInput: pipe];
	
	NSPipe *pipe2 = [NSPipe pipe];
	[t2 setStandardOutput: pipe2];
	
	NSFileHandle *file = [pipe2 fileHandleForReading];
	int the_index = 0;
	NSMenu *m = [[NSMenu alloc] initWithTitle: @"Testing"];	
	int i;

	NSArray *untracked = [self getUntracked];

	if (untracked && [untracked count])
		untrackedFiles = YES;
	else
		untrackedFiles = NO;
	
	NSArray *logs = [self
		arrayFromResultOfArgs: [NSArray arrayWithObjects: @"log", @"-l", @"10", @"--template", @"{node|short} {date|age} {desc}\n", nil]
		withName: @"Mercurial::fire::logs"];
	NSFont *firstFont = [NSFont userFixedPitchFontOfSize: 16.0];
	NSFont *secondFont = [NSFont userFixedPitchFontOfSize: 12.0];
	NSMenuItem *mi;
	if ([logs count] == 0) {
		mi = [[NSMenuItem alloc] initWithTitle: @"No history for this project" action: nil keyEquivalent: @""];
		[m addItem: mi];
		the_index++;
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
				the_index++;
			}
		}
	}
	
	[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];

	[t autorelease];
	[t2 autorelease];
	
	@try {
		[t launch];
		[t2 launch];
		
		NSData *data = [file readDataToEndOfFile];
		NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSString *utf8String = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
		NSString *string = [utf8String stringByTrimmingCharactersInSet: cs];

		NSArray *arr = [string componentsSeparatedByString: @"\n"];
		NSString *s2 = [arr objectAtIndex: [arr count] - 1];
		s2 = [s2 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	

		if (untrackedFiles) {
			NSString *s = [NSString stringWithFormat: @"%@: %d untracked files", [repository lastPathComponent], [untracked count]];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self setTitle: s];
				[self setShortTitle: s];
				[menuItem setHidden: NO];
			});
		} else if (![s2 isEqual: @"0 files changed"]) {
			localMod = YES;
			[[m insertItemWithTitle: @"Commit these changes" action: @selector(commit:) keyEquivalent: @"" atIndex: the_index] setTarget: self];
			NSString *sTit = [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], [self shortenDiff: s2]];
		
			[self setAllTitles: sTit];
		} else {
			localMod = NO;
			[dirtyLock lock];
			dirty = YES;
			[dirtyLock unlock];

			NSString *sTit = [NSString stringWithFormat: @"%@",
				[repository lastPathComponent]];

			[self setAllTitles: sTit];
		}
		[[m insertItemWithTitle: @"Open in Finder" action: @selector(openInFinder:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
		[[m insertItemWithTitle: @"Open in Terminal" action: @selector(openInTerminal:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
		[[m insertItemWithTitle: @"Ignore" action: @selector(ignore:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];

		dispatch_async(dispatch_get_main_queue(), ^{
			if (localMod)
				[menuItem setOffStateImage: mc->redBubble];
			else if (upstreamMod)
				[menuItem setOffStateImage: mc->yellowBubble];
			else
				[menuItem setOffStateImage: mc->greenBubble];
			[menuItem setSubmenu: m];
		});
	} @catch (NSException *e) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self hideIt];
		});
	}
	dispatch_async(dispatch_get_main_queue(), ^{
		[self setupTimer];
	});
}

@end