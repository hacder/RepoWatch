#import "GitDiffButtonDelegate.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc gitPath: (char *)gitPath repository: (NSString *)rep
		window: (NSWindow *)commitWindow {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc repository: rep];
	git = gitPath;
	[self setHidden: YES];
	[menuItem setAction: nil];
	
	diffCommitTV = mc->diffCommitTextView;
	[diffCommitTV retain];
	
	window = commitWindow;
	[window retain];
	
	[self fire];
	[self updateRemote];
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

- (void) updateRemote {
	NSTask *t;
	NSFileHandle *file;
	NSString *string;
	NSArray *arr;
	
	arr = [NSArray arrayWithObjects: @"remote", nil];
	t = [[self taskFromArguments: arr] autorelease];
	file = [self pipeForTask: t];
	[t launch];
	
	string = [self stringFromFile: file];
	string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (![string length])
		return;
	
	t = [self taskFromArguments: [NSArray arrayWithObjects: @"fetch", nil]];
	[t launch];
	[t autorelease];
}
	
- (NSString *) getDiffRemote: (BOOL)remote {
	NSArray *arr;
	NSTask *t;
	NSFileHandle *file;
	NSString *string;
	
	if (remote) {
		arr = [NSArray arrayWithObjects: @"remote", nil];
		t = [[self taskFromArguments: arr] autorelease];
		file = [self pipeForTask: t];
		[t launch];
		string = [self stringFromFile: file];
		string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (![string length]) {
			upstreamMod = NO;
			return nil;
		}
		string = [NSString stringWithFormat: @"HEAD...%@", string];
		arr = [NSArray arrayWithObjects: @"diff", @"--shortstat", string, nil];
	} else {
		arr = [NSArray arrayWithObjects: @"diff", @"--shortstat", nil];
	}
	t = [[self taskFromArguments: arr] autorelease];
	file = [self pipeForTask: t];	
	[t launch];
	string = [self stringFromFile: file];
	[file closeFile];
	
	return string;
}

- (NSString *)getDiff {
	NSArray *arr = [NSArray arrayWithObjects: @"diff", nil];
	NSTask *t = [[self taskFromArguments: arr] autorelease];
	NSFileHandle *file = [self pipeForTask: t];
	[t launch];
	NSString *result = [self stringFromFile: file];
	[file closeFile];
	return result;
}

- (void) commit: (id) menuItem {
	[window setTitle: repository];
	[window makeFirstResponder: mc->tv];

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
		[t launch];
		
		NSString *string = [self stringFromFile: file];
		[file closeFile];
		[mc->tv setString: string];
		[mc->tv setEditable: NO];
	}
	[window center];
	[NSApp activateIgnoringOtherApps: YES];
	[window makeKeyAndOrderFront: NSApp];
	[window makeFirstResponder: mc->tv];
}

- (void) upstreamUpdate: (id) sender {
	[sender setEnabled: NO];
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"rebase", @"origin", nil]] autorelease];
	[t launch];
}

- (void) clickUpdate: (id) button {
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"commit", @"-a", @"-m", [[mc->tv textStorage] mutableString], nil]] autorelease];
	[t launch];
	if (window)
		[window close];
	
	[NSApp hide: self];
}

- (void) clickLog: (id) clicker {
	[mc->diffCommitWindow setTitle: repository];
	[mc->diffCommitWindow makeFirstResponder: diffCommitTV];
	
	NSArray *parts = [[clicker title] componentsSeparatedByString: @" "];
	NSString *revisionID = [parts objectAtIndex: 0];

	NSArray *arr = [NSArray arrayWithObjects: @"diff", revisionID, [NSString stringWithFormat: @"%@^", revisionID], nil];
	NSTask *t = [[self taskFromArguments: arr] autorelease];
	NSFileHandle *file = [self pipeForTask: t];
	[t launch];
	NSString *result = [self stringFromFile: file];
	[file closeFile];
	[diffCommitTV setString: result];
	
	[mc->diffCommitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->diffCommitWindow makeKeyAndOrderFront: NSApp];
	[mc->diffCommitWindow makeFirstResponder: diffCommitTV];
}

- (void) fire {
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		int the_index = 0;
		
		[lock lock];
		NSString *remoteString = [self getDiffRemote: YES];		
		NSString *string = [self getDiffRemote: NO];
		if (string == nil) {
			[lock unlock];
			return;
		}
		
		// Leaking branches
		NSArray *arguments = [NSArray arrayWithObjects: @"branch", nil];
		NSArray *branches = [self arrayFromResultOfArgs: arguments];

		NSMenu *m = [[[NSMenu alloc] initWithTitle: @"Testing"] autorelease];
		// Leaking NSMenuItem here
		[m insertItemWithTitle: @"Branches" action: @selector(branch:) keyEquivalent: @"" atIndex: 0];
		[m insertItem: [NSMenuItem separatorItem] atIndex: 1];

		int i;
		the_index = 2;
		for (i = 0; i < [branches count]; i++) {
			NSString *tmp = [branches objectAtIndex: i];
			if (tmp && [tmp length] > 0) {
				// Leaking NSMenuItem here
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
		
		// Leaking these logs.
		NSArray *logs = [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"log", @"-n", @"5", @"--pretty=oneline", @"--abbrev-commit", nil]];
		for (i = 0; i < [logs count]; i++) {
			NSString *tmp = [logs objectAtIndex: i];
			if (tmp && [tmp length] > 0) {
				// Leak: NSMenuItem
				[m insertItemWithTitle: tmp action: nil keyEquivalent: @"" atIndex: the_index++];
			}
		}
		
		[m insertItemWithTitle: @"" action: nil keyEquivalent: @"" atIndex: the_index++];
		[m insertItemWithTitle: @"Actions" action: nil keyEquivalent: @"" atIndex: the_index++];
		[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];

		if (!remoteString || [remoteString isEqual: @""]) {
			if ([string isEqual: @""]) {
				localMod = NO;
				upstreamMod = NO;
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
				upstreamMod = NO;
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
		} else {
			// There is a remote diff.
			NSString *sTit;
			localMod = NO;
			upstreamMod = YES;
			[[m insertItemWithTitle: @"Update from origin" action: @selector(commit:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
			if (currentBranch == nil || [currentBranch isEqual: @"master"]) {
				sTit = [NSString stringWithFormat: @"*Remote* %@: %@",
					[repository lastPathComponent],
					[remoteString stringByTrimmingCharactersInSet:
						[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			} else {
				sTit = [NSString stringWithFormat: @"*Remote* %@: %@ (%@)",
					[repository lastPathComponent],
					[remoteString stringByTrimmingCharactersInSet:
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