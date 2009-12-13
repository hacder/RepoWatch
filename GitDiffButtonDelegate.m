#import "GitDiffButtonDelegate.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc gitPath: (char *)gitPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mc repository: rep];
	git = gitPath;
	[self setHidden: YES];
	[self fire];
	lock = [[NSLock alloc] init];
	[menuItem setAction: nil];
	tv = nil;
	window = nil;
	return self;
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	NSTask *t = [[NSTask alloc] init];
	NSString *lp = [NSString stringWithFormat: @"%s", git];
	[t setLaunchPath: lp];
	[t setCurrentDirectoryPath: repository];
	[t setArguments: args];

	return t;
}
	
- (NSFileHandle *)pipeForTask: (NSTask *)t {
	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	return file;
}

- (NSString *)stringFromFile: (NSFileHandle *)file {
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[[NSString alloc] initWithData: data
			encoding: NSUTF8StringEncoding] autorelease];
	return string;
}

- (NSString *) getDiff {
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"diff", @"--shortstat", nil]] autorelease];
	NSFileHandle *file = [self pipeForTask: t];
	
	@try {
		[t launch];
	} @catch (NSException *e) {
		[self setTitle: @"Errored"];
		[self setHidden: YES];
		localMod = NO;
		upstreamMod = NO;
		return nil;
	}
	
	NSString *string = [self stringFromFile: file];
	[file closeFile];
	
	return string;
}

- (NSArray *)arrayFromResultOfArgs: (NSArray *)args {
	NSTask *t = [[self taskFromArguments: args] autorelease];
	NSFileHandle *file = [self pipeForTask: t];
	// TODO: Wrap in try/catch
	[t launch];
	
	NSString *string = [self stringFromFile: file];
	NSArray *result = [string componentsSeparatedByString: @"\n"];
	[file closeFile];
	return result;
}

- (void) commit: (id) menuItem {
	[tv autorelease];
	[window autorelease];
	
	NSRect frame = NSMakeRect(0, 0, 200, 200);
	NSUInteger styleMask = NSTitledWindowMask | NSClosableWindowMask;
	NSRect rect = [NSWindow contentRectForFrameRect: frame styleMask: styleMask];
	window  = [[NSWindow alloc] initWithContentRect: rect styleMask: styleMask backing: NSBackingStoreBuffered defer: NO];
	[window setTitle: [repository lastPathComponent]];
	NSRect rect2;
	rect2.origin.x = [[window contentView] frame].origin.x + 5;
	rect2.origin.y = [[window contentView] frame].origin.y + 40;
	rect2.size.width = [[window contentView] frame].size.width - 10;
	rect2.size.height = [[window contentView] frame].size.height - 45;
	tv = [[NSTextView alloc] initWithFrame: rect2];
	[[window contentView] addSubview: tv];
	[window makeFirstResponder: tv];

	rect2.origin.y = 5;
	rect2.size.height = 30;
	NSButton *butt = [[NSButton alloc] initWithFrame: rect2];
	[butt setKeyEquivalent: @"\r"];
	[butt setKeyEquivalentModifierMask: NSCommandKeyMask];
	[butt setBezelStyle: NSRoundedBezelStyle];
	[butt setTitle: @"Do Commit"];
	[[window contentView] addSubview: butt];
	[butt setTarget: self];
	[butt setAction: @selector(clickUpdate:)];
	[window center];
	[NSApp activateIgnoringOtherApps: YES];
	[window makeKeyAndOrderFront: NSApp];
	NSLog(@"First responder attempt: %d", [window makeFirstResponder: tv]);
}

- (void) clickUpdate: (id) button {
	if (tv == nil)
		return;
	
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"commit", @"-a", @"-m", [[tv textStorage] mutableString], nil]] autorelease];
	[t launch];
	if (window) {
		[window close];
		window = nil;
	}
	
	tv = nil;
}

- (void) fire {
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		int the_index = 0;
		
		[lock lock];
		NSString *string = [self getDiff];
		if (string == nil) {
			[lock unlock];
			return;
		}
		
		NSArray *branches = [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"branch", nil]];

		NSMenu *m = [[NSMenu alloc] initWithTitle: @"Testing"];
		[m insertItemWithTitle: @"Branches" action: @selector(branch:) keyEquivalent: @"" atIndex: 0];
		[m insertItem: [NSMenuItem separatorItem] atIndex: 1];

		int i;
		the_index = 2;
		for (i = 0; i < [branches count]; i++) {
			NSString *tmp = [branches objectAtIndex: i];
			if (tmp && [tmp length] > 0) {
				[m insertItemWithTitle: tmp action: nil keyEquivalent: @"" atIndex: the_index++];
				if ('*' == [tmp characterAtIndex: 0]) {
					tmp = [tmp stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @" \n*\r"]];
					[currentBranch autorelease];
					currentBranch = tmp;
					[currentBranch retain];
				} else {
					tmp = [tmp stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @" \n*\r"]];
				}
			}
		}
		
		[m insertItemWithTitle: @"" action: nil keyEquivalent: @"" atIndex: the_index++];
		[m insertItemWithTitle: @"Logs" action: nil keyEquivalent: @"" atIndex: the_index++];
		[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];
		
		NSArray *logs = [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"log", @"-n", @"5", @"--pretty=oneline", @"--abbrev-commit", nil]];
		for (i = 0; i < [logs count]; i++) {
			NSString *tmp = [logs objectAtIndex: i];
			if (tmp && [tmp length] > 0) {
				[m insertItemWithTitle: tmp action: nil keyEquivalent: @"" atIndex: the_index++];
			}
		}
		
		[m insertItemWithTitle: @"" action: nil keyEquivalent: @"" atIndex: the_index++];
		[m insertItemWithTitle: @"Actions" action: nil keyEquivalent: @"" atIndex: the_index++];
		[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];

		if ([string isEqual: @""]) {
			localMod = NO;
			dispatch_async(dispatch_get_main_queue(), ^{
				[lock lock];
				NSString *s3;
				if (currentBranch == nil || [currentBranch isEqual: @"master"]) {
					s3 = [NSString stringWithFormat: @"git: %@",
						[repository lastPathComponent]];
				} else {
					s3 = [NSString stringWithFormat: @"git: %@ (%@)",
							[repository lastPathComponent], currentBranch];
				}
				[self setTitle: s3];
				[self setShortTitle: s3];
				[self setHidden: NO];
				[lock unlock];
			});
		} else {
			NSString *sTit;
			localMod = YES;
			[[m insertItemWithTitle: @"Commit these changes" action: @selector(commit:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
			if (currentBranch == nil || [currentBranch isEqual: @"master"]) {
				sTit = [NSString stringWithFormat: @"%@: %@",
					[repository lastPathComponent],
					[string stringByTrimmingCharactersInSet:
						[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			} else {
				sTit = [NSString stringWithFormat: @"%@: %@ (%@)",
					[repository lastPathComponent],
					[string stringByTrimmingCharactersInSet:
					[NSCharacterSet whitespaceAndNewlineCharacterSet]], currentBranch];
			}
			dispatch_async(dispatch_get_main_queue(), ^{
				[lock lock];
				[self setTitle: sTit];
				[self setShortTitle: sTit];
				[self setHidden: NO];
				[lock unlock];
			});
		}
		dispatch_async(dispatch_get_main_queue(), ^{
			[lock lock];
			[menuItem setSubmenu: m];
			[lock unlock];
		});
		[lock unlock];
	});
}

@end