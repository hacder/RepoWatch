#import "GitDiffButtonDelegate.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc gitPath: (char *)gitPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc repository: rep];
	git = gitPath;
	[menuItem setHidden: YES];
	[menuItem setAction: nil];
	
	diffCommitTV = mc->diffCommitTextView;
	[diffCommitTV retain];
	
	[self fire];
	[self updateRemote];
	return self;
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	NSString *lp = [NSString stringWithFormat: @"%s", git];
	return [self baseTask: lp fromArguments: args];
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
	[t waitUntilExit];
	if ([t terminationStatus] != 0)
		NSLog(@"Git Update Remote <remote>, task status: %d", [t terminationStatus]);
	
	string = [self stringFromFile: file];
	string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (![string length])
		return;
	
	t = [self taskFromArguments: [NSArray arrayWithObjects: @"fetch", nil]];
	[t launch];
	[t waitUntilExit];
	if ([t terminationStatus] != 0) {
		NSLog(@"Failed to fetch upstream for %@!", repository);
	}
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
		[t waitUntilExit];
		if ([t terminationStatus] != 0)
			NSLog(@"Git getDiffRemote <remote>, task status: %d", [t terminationStatus]);
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
	[t waitUntilExit];
	if ([t terminationStatus] != 0)
		NSLog(@"Git getDiffRemote <diff>, task status: %d", [t terminationStatus]);
	string = [self stringFromFile: file];
	[file closeFile];
	
	return [self shortenDiff: string];
}

- (void) commit: (id) menuItem {
	[mc->commitWindow setTitle: repository];
	[mc->commitWindow makeFirstResponder: mc->tv];

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
		[t waitUntilExit];
		if ([t terminationStatus] != 0)
			NSLog(@"Git commit, task status: %d", [t terminationStatus]);
		
		NSString *string = [self stringFromFile: file];
		[file closeFile];
		[mc->tv setString: string];
		[mc->tv setEditable: NO];
	}
	[mc->commitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->commitWindow makeKeyAndOrderFront: NSApp];
	[mc->commitWindow makeFirstResponder: mc->tv];
}

- (void) upstreamUpdate: (id) sender {
	[sender setEnabled: NO];
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"rebase", @"origin", nil]] autorelease];
	[t launch];
	[t waitUntilExit];
	if ([t terminationStatus] != 0)
		NSLog(@"Git upstreamUpdate, task status: %d", [t terminationStatus]);
}

- (void) clickUpdate: (id) button {
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"commit", @"-a", @"-m", [[mc->tv textStorage] mutableString], nil]] autorelease];
	[t launch];
	[t waitUntilExit];
	if ([t terminationStatus] != 0)
		NSLog(@"Git clickUpdate, task status: %d", [t terminationStatus]);
	if (mc->commitWindow)
		[mc->commitWindow close];
	
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
	[t waitUntilExit];
	if ([t terminationStatus] != 0)
		NSLog(@"Git clickLog, task status: %d", [t terminationStatus]);
	NSString *result = [self stringFromFile: file];
	[file closeFile];
	[diffCommitTV setString: result];
	
	[mc->diffCommitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->diffCommitWindow makeKeyAndOrderFront: NSApp];
	[mc->diffCommitWindow makeFirstResponder: diffCommitTV];
}

- (int) doBranchesForMenu: (NSMenu *)m {
	NSArray *arguments = [NSArray arrayWithObjects: @"branch", nil];
	NSArray *branches = [self arrayFromResultOfArgs: arguments];

	int i;
	int the_index = 0;
	
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
	
	return the_index;
}

- (int) doLogsForMenu: (NSMenu *)m atIndex: (int)the_index {
	int i;
	
	[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];
	
	NSArray *logs = [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"log", @"-n", @"10", @"--pretty=oneline", @"--abbrev-commit", nil]];
	NSFont *firstFont = [NSFont userFixedPitchFontOfSize: 16.0];
	NSFont *secondFont = [NSFont userFixedPitchFontOfSize: 12.0];

	for (i = 0; i < [logs count]; i++) {
		NSString *tmp = [logs objectAtIndex: i];
		NSDictionary *attributes;
		if (i == 0) {
			attributes = [NSDictionary dictionaryWithObject: firstFont forKey: NSFontAttributeName];
		} else {
			attributes = [NSDictionary dictionaryWithObject: secondFont forKey: NSFontAttributeName];
		}
		NSAttributedString *attr = [[NSAttributedString alloc] initWithString: tmp attributes: attributes];
		if (tmp && [tmp length] > 0) {
			NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle: tmp action: nil keyEquivalent: @""];
			[mi setAttributedTitle: attr];
			[m addItem: mi];
			the_index++;
		}
	}
	
	return the_index;
}

- (void) noMods {
	localMod = NO;
	upstreamMod = NO;
	dispatch_sync(dispatch_get_main_queue(), ^{
		NSString *s3;
		if (currentBranch == nil || [currentBranch isEqual: @"master"]) {
			s3 = [NSString stringWithFormat: @"%@",
				[repository lastPathComponent]];
		} else {
			s3 = [NSString stringWithFormat: @"%@ (%@)",
					[repository lastPathComponent], currentBranch];
		}
		[self setTitle: s3];
		[self setShortTitle: s3];
		[menuItem setHidden: NO];
	});
}

- (void) localModsWithMenu: (NSMenu *)m index: (int)the_index string: (NSString *)string {
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
	dispatch_sync(dispatch_get_main_queue(), ^{
		[self setTitle: sTit];
		[self setShortTitle: sTit];
		[menuItem setHidden: NO];
	});
}

- (void) realFire {
	int the_index = 0;
	
	NSString *remoteString = [self getDiffRemote: YES];		
	NSString *string = [self getDiffRemote: NO];
	if (string == nil)
		return;
	
	NSMenu *m = [[[NSMenu alloc] initWithTitle: @"Testing"] autorelease];

	the_index = [self doBranchesForMenu: m];
	the_index = [self doLogsForMenu: m atIndex: the_index];
	[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];

	if (!remoteString || [remoteString isEqual: @""]) {
		if ([string isEqual: @""]) {
			[self noMods];
		} else {
			[self localModsWithMenu: m index: the_index string: string];
		}
	} else {
		// There is a remote diff.
		NSString *sTit;
		localMod = NO;
		upstreamMod = YES;
		[[m insertItemWithTitle: @"Update from origin" action: @selector(commit:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
		sTit = [NSString stringWithFormat: @"*Remote* %@: %@",
			[repository lastPathComponent],
			[remoteString stringByTrimmingCharactersInSet:
				[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self setTitle: sTit];
			[self setShortTitle: sTit];
			[menuItem setHidden: NO];
		});
	}
	[[m insertItemWithTitle: @"Open in Finder" action: @selector(openInFinder:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
	[[m insertItemWithTitle: @"Open in Terminal" action: @selector(openInTerminal:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
	[[m insertItemWithTitle: @"Ignore" action: @selector(ignore:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];

	dispatch_sync(dispatch_get_main_queue(), ^{
		if (localMod)
			[menuItem setImage: mc->redBubble];
		else if (upstreamMod)
			[menuItem setImage: mc->yellowBubble];
		else
			[menuItem setImage: mc->greenBubble];
		[menuItem setSubmenu: m];
	});
}

- (void) fire {
	if (![lock tryLock])
		return;
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[self realFire];
		dispatch_async(dispatch_get_main_queue(), ^{
			[lock unlock];
		});
	});
}

@end