#import "MercurialDiffButtonDelegate.h"

@implementation MercurialDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc hgPath: (char *)hgPath repository: (NSString *)rep window: (NSWindow *)commitWindow textView: (NSTextView *)tv2 button: (NSButton *)butt2{
	self = [super initWithTitle: s menu: m statusItem: si mainController: mc repository: rep];
	hg = hgPath;
	tv = tv2;
	[tv retain];
	butt = butt2;
	[butt retain];
	window = commitWindow;
	[window retain];
	[self fire];
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
	[window setTitle: repository];
	[window makeFirstResponder: tv];

	[tv setString: @""];
	[tv setNeedsDisplay: YES];
	if (localMod) {	
		[butt setTitle: @"Do Commit"];
		[butt setTarget: self];
		[butt setAction: @selector(clickUpdate:)];
	} else if (upstreamMod) {
		NSArray *arr = [NSArray arrayWithObjects: @"log", @"HEAD..origin", @"--abbrev-commit", @"--pretty=%h %an %s", nil];
		NSTask *t = [[self taskFromArguments: arr] autorelease];
		NSFileHandle *file = [self pipeForTask: t];
		
		[butt setTitle: @"Update from upstream"];
		[butt setTarget: self];
		[butt setAction: @selector(upstreamUpdate:)];
		@try {
			[t launch];
		} @catch (NSException *e) {
			[self setTitle: @"Errored"];
			[self setHidden: YES];
			localMod = NO;
			upstreamMod = NO;
			return;
		}
		
		NSString *string = [self stringFromFile: file];
		[file closeFile];
		[tv insertText: string];
		[tv setEditable: NO];
	}
	[window center];
	[NSApp activateIgnoringOtherApps: YES];
	[window makeKeyAndOrderFront: NSApp];
	[window makeFirstResponder: tv];
}

- (void) clickUpdate: (id) button {
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"commit", @"-m", [[tv textStorage] mutableString], nil]] autorelease];
	[t launch];
	if (window)
		[window close];
	
	[NSApp hide: self];
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

- (void) fire {
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
	
		NSArray *branches = [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"branches", nil]];
	
		NSMenu *m = [[NSMenu alloc] initWithTitle: @"Testing"];
		[m insertItemWithTitle: @"Branches" action: @selector(branch:) keyEquivalent: @"" atIndex: 0];
		[m insertItem: [NSMenuItem separatorItem] atIndex: 1];
	
		int i;
		int the_index = 2;
		for (i = 0; i < [branches count]; i++) {
			NSString *tmp = [branches objectAtIndex: i];
			if (tmp && [tmp length] > 0) {
				[m insertItemWithTitle: tmp action: nil keyEquivalent: @"" atIndex: the_index++];
				if ('*' == [tmp characterAtIndex: 0]) {
					tmp = [tmp stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @" \n*\r"]];
				} else {
					tmp = [tmp stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @" \n*\r"]];
				}
			}
		}
	
		[m insertItemWithTitle: @"" action: nil keyEquivalent: @"" atIndex: the_index++];
		[m insertItemWithTitle: @"Logs" action: nil keyEquivalent: @"" atIndex: the_index++];
		[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];
		
		NSArray *logs = [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"log", @"--template", @"{node|short} {desc}\n", nil]];
		for (i = 0; i < [logs count]; i++) {
			NSString *tmp = [logs objectAtIndex: i];
			if (tmp && [tmp length] > 0) {
				[m insertItemWithTitle: tmp action: nil keyEquivalent: @"" atIndex: the_index++];
			}
		}
		
		[m insertItemWithTitle: @"" action: nil keyEquivalent: @"" atIndex: the_index++];
		[m insertItemWithTitle: @"Actions" action: nil keyEquivalent: @"" atIndex: the_index++];
		[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];

		[t autorelease];
		[t2 autorelease];
		
		[t launch];
		[t2 launch];
		
		NSData *data = [file readDataToEndOfFile];
		NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSString *utf8String = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		NSString *string = [[utf8String stringByTrimmingCharactersInSet: cs] retain];

		NSArray *arr = [string componentsSeparatedByString: @"\n"];
		NSString *s2 = [arr objectAtIndex: [arr count] - 1];
		s2 = [s2 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
		if (![s2 isEqual: @"0 files changed"]) {
			localMod = YES;
			[[m insertItemWithTitle: @"Commit these changes" action: @selector(commit:) keyEquivalent: @"" atIndex: the_index] setTarget: self];
			NSString *sTit = [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], s2];
		
			[self setAllTitles: sTit];
		} else {
			localMod = NO;
			NSString *sTit = [NSString stringWithFormat: @"hg: %@",
				[repository lastPathComponent]];

			[self setAllTitles: sTit];
		}
		[lock unlock];
		dispatch_async(dispatch_get_main_queue(), ^{
			[lock lock];
			NSLog(@"Got here");
			[menuItem setSubmenu: m];
			[lock unlock];
		});
	});
}

@end