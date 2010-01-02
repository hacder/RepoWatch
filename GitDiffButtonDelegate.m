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
	@try {
		[t launch];
		[t waitUntilExit];
		if ([t terminationStatus] != 0)
			NSLog(@"Git Update Remote <remote>, task status: %d", [t terminationStatus]);
	
		string = [self stringFromFile: file];
		string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (![string length])
			return;
		
		NSLog(@"Updating remote for %@", repository);
		
		t = [[self taskFromArguments: [NSArray arrayWithObjects: @"fetch", nil]] autorelease];
		@try {
			[t launch];
			[t waitUntilExit];
			if ([t terminationStatus] != 0) {
				NSLog(@"Failed to fetch upstream for %@!", repository);
			}
		} @catch (NSException *e) {
			[self hideIt];
			return;
		}
	} @catch (NSException *e) {
		[self hideIt];
		return;
	}
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
		@try {
			[t launch];
			[t waitUntilExit];
			if ([t terminationStatus] != 0)
				NSLog(@"Git getDiffRemote <remote>, task status: %d", [t terminationStatus]);
			string = [self stringFromFile: file];
			string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if (![string length]) {
				upstreamMod = NO;
				return nil;
			} else {
				upstreamMod = YES;
			}
			string = [NSString stringWithFormat: @"HEAD...%@", string];
			arr = [NSArray arrayWithObjects: @"diff", @"--shortstat", string, nil];
		} @catch (NSException *e) {
			[self hideIt];
			return nil;
		}
	} else {
		arr = [NSArray arrayWithObjects: @"diff", @"--shortstat", nil];
	}
	t = [[self taskFromArguments: arr] autorelease];
	file = [self pipeForTask: t];
	@try {
		[t launch];
		[t waitUntilExit];
		if ([t terminationStatus] != 0)
			NSLog(@"Git getDiffRemote <diff>, task status: %d", [t terminationStatus]);
		string = [self stringFromFile: file];
		[file closeFile];
		return [self shortenDiff: string];
	} @catch (NSException *e) {
		[self hideIt];
		return nil;
	}
	
	return nil;
}

- (void) commit: (id) menuItem {
	[mc->commitWindow setTitle: repository];
	[mc->commitWindow makeFirstResponder: mc->tv];

	if (localMod) {	
		[mc->tv setEditable: YES];
		NSString *diffString = [self getDiff];
		[mc->tv setString: @""];
		[mc->diffView setString: diffString];
		[mc->butt setTitle: @"Do Commit"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(clickUpdate:)];
	} else if (upstreamMod) {
		NSArray *arr = [NSArray arrayWithObjects: @"log", @"HEAD..origin", @"--abbrev-commit", @"--pretty=%h %s", nil];
		NSTask *t = [[self taskFromArguments: arr] autorelease];
		NSFileHandle *file = [self pipeForTask: t];
		
		[mc->butt setTitle: @"Update from upstream"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(upstreamUpdate:)];
		@try {
			[t launch];
			[t waitUntilExit];
			if ([t terminationStatus] != 0)
				NSLog(@"Git commit, task status: %d", [t terminationStatus]);
			
			NSString *string = [self stringFromFile: file];
			[file closeFile];
			[mc->tv setString: string];
			[mc->tv setEditable: NO];
			
			arr = [NSArray arrayWithObjects: @"diff", @"HEAD..origin", nil];
			t = [[self taskFromArguments: arr] autorelease];
			file = [self pipeForTask: t];
			
			@try {
				[t launch];
				string = [self stringFromFile: file];
				[file closeFile];
				[mc->diffView setString: string];
				[mc->diffView setEditable: NO];
			} @catch (NSException *e) {
				[self hideIt];
				return;
			}
		} @catch (NSException *e) {
			[self hideIt];
			return;
		}
	}
	[mc->commitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->commitWindow makeKeyAndOrderFront: NSApp];
	[mc->commitWindow makeFirstResponder: mc->tv];
}

- (void) upstreamUpdate: (id) sender {
	[sender setEnabled: NO];
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"rebase", @"origin", nil]] autorelease];
	@try {
		[t launch];
		[t waitUntilExit];
		if ([t terminationStatus] != 0)
			NSLog(@"Git upstreamUpdate, task status: %d", [t terminationStatus]);
		[sender setEnabled: YES];
		[mc->commitWindow close];
		[NSApp hide: self];
	} @catch (NSException *e) {
		[self hideIt];
		return;
	}
}

- (void) clickUpdate: (id) button {
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"commit", @"-a", @"-m", [[mc->tv textStorage] mutableString], nil]] autorelease];
	@try {
		[t launch];
		[t waitUntilExit];
		if ([t terminationStatus] != 0)
			NSLog(@"Git clickUpdate, task status: %d", [t terminationStatus]);
		if (mc->commitWindow)
			[mc->commitWindow close];
		
		[NSApp hide: self];
	} @catch (NSException *e) {
		[self hideIt];
		return;
	}
}

- (void) clickLog: (id) clicker {
	[mc->diffCommitWindow setTitle: repository];
	[mc->diffCommitWindow makeFirstResponder: diffCommitTV];
	
	NSArray *parts = [[clicker title] componentsSeparatedByString: @" "];
	NSString *revisionID = [parts objectAtIndex: 0];

	NSArray *arr = [NSArray arrayWithObjects: @"diff", revisionID, [NSString stringWithFormat: @"%@^", revisionID], nil];
	NSTask *t = [[self taskFromArguments: arr] autorelease];
	NSFileHandle *file = [self pipeForTask: t];
	@try {
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
	} @catch (NSException *e) {
		[self hideIt];
		return;
	}
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

	[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];	
	
	return the_index;
}

- (int) doLogsForMenu: (NSMenu *)m atIndex: (int)the_index {
	int i;
	
	NSArray *logs = [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"log", @"-n", @"10",
			@"--format=%h %ar %s", @"--abbrev-commit", nil]];
	NSFont *firstFont = [NSFont userFixedPitchFontOfSize: 16.0];
	NSFont *secondFont = [NSFont userFixedPitchFontOfSize: 12.0];
	NSMenuItem *mi;

	if ([logs count] == 1) {
		NSLog(@"Thinks that there is no log: %@", logs);
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
			NSAttributedString *attr = [[NSAttributedString alloc] initWithString: tmp attributes: attributes];
			if (tmp && [tmp length] > 0) {
				mi = [[NSMenuItem alloc] initWithTitle: tmp action: nil keyEquivalent: @""];
				[mi setAttributedTitle: attr];
				[m addItem: mi];
				the_index++;
			}
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
	
	NSMenu *m = [[[NSMenu alloc] initWithTitle: @"Testing"] autorelease];

//	the_index = [self doBranchesForMenu: m];
	the_index = [self doLogsForMenu: m atIndex: the_index];
	[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];

	if (!remoteString || [remoteString isEqual: @""]) {
		if (string == nil || [string isEqual: @""]) {
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
		sTit = [NSString stringWithFormat: @"%@: %@",
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
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self fire];
		});
		return;
	}
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