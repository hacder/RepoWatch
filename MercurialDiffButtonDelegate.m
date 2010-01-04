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
		NSTask *t = [[self taskFromArguments: arr] autorelease];
		NSFileHandle *file = [self pipeForTask: t];
		
		[mc->butt setTitle: @"Update from upstream"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(upstreamUpdate:)];
		@try {
			[t launch];
		} @catch (NSException *e) {
			[self hideIt];
			return;
		}
		
		NSString *string = [self stringFromFile: file];
		[file closeFile];
		[mc->tv insertText: string];
		[mc->tv setEditable: NO];
	}
	[mc->commitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->commitWindow makeKeyAndOrderFront: NSApp];
	[mc->commitWindow makeFirstResponder: mc->tv];
}

- (void) clickUpdate: (id) button {
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"commit", @"-m", [[mc->tv textStorage] mutableString], nil]] autorelease];
	@try {
		[t launch];
		if (mc->commitWindow)
			[mc->commitWindow close];
		
		[NSApp hide: self];
	} @catch (NSException *e) {
		[self hideIt];
		return;
	}
}

- (void) setAllTitles: (NSString *)s {
	[s retain];
	dispatch_async(dispatch_get_main_queue(), ^{
		[lock lock];
		[s autorelease];
		[self setTitle: s];
		[self setShortTitle: s];
		[lock unlock];
	});
}

- (void) fire: (NSTimer *)t {
	if (![[NSFileManager defaultManager] fileExistsAtPath: repository]) {
		localMod = NO;
		upstreamMod = NO;
		[menuItem setHidden: YES];
		return;
	}
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[lock lock];
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
		
			if (![s2 isEqual: @"0 files changed"]) {
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
	
			[lock unlock];
			dispatch_async(dispatch_get_main_queue(), ^{
				[lock lock];
				if (localMod)
					[menuItem setImage: mc->redBubble];
				else if (upstreamMod)
					[menuItem setImage: mc->yellowBubble];
				else
					[menuItem setImage: mc->greenBubble];
				[menuItem setSubmenu: m];
				[lock unlock];
			});
		} @catch (NSException *e) {
			[self hideIt];
			[self setupTimer];
			return;
		}
		[self setupTimer];
	});
}

@end