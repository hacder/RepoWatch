#import "GitDiffButtonDelegate.h"
#import "BubbleFactory.h"
#import "RepoHelper.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc
		gitPath: (char *)gitPath repository: (NSString *)rep {

	git = gitPath;
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc repository: rep];
	[menuItem setAction: nil];
	
	diffCommitTV = mc->diffCommitTextView;
	[diffCommitTV retain];
	
	[self fire: nil];
	[self updateRemote];
	return self;
}

- (void) checkLocal: (NSTimer *)ti {
	NSArray *arr = [NSArray arrayWithObjects: @"diff", @"--shortstat", nil];
	NSTask *t = [self taskFromArguments: arr];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		if (![resultarr count]) {
			[localDiffSummary autorelease];
			localDiffSummary = nil;
			[localDiff autorelease];
			localDiff = nil;
			localMod = NO;
			[super checkLocal: ti];
			[self realFire];
			return;
		}
		localMod = YES;
		[localDiffSummary autorelease];
		localDiffSummary = [resultarr objectAtIndex: 0];
		[localDiffSummary retain];
		
		NSArray *arr = [NSArray arrayWithObjects: @"diff", nil];
		NSTask *t = [self taskFromArguments: arr];
		[tq addTask: t withCallback: ^(NSArray *resultarr) {
			[localDiff autorelease];
			localDiff = [resultarr componentsJoinedByString: @"\n"];
			[localDiff retain];
			[super checkLocal: ti];
			[self realFire];			
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
	NSString *path = [NSString stringWithFormat: @"%@/%@", repository, @".gitignore"];
	NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath: path];
	if (fh == nil) {
		[@".gitignore\n" writeToFile: path atomically: NO encoding: NSASCIIStringEncoding error: nil];
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

- (void)getUntrackedWithCallback: (void (^)(NSArray *)) callback {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"ls-files", @"--others", @"--exlcude-standard", @"-z", nil]];
	[tq addTask: t withCallback: ^(NSArray *arr) {
		NSMutableArray *arrmut = [NSMutableArray arrayWithArray: arr];
		int i;
		for (i = 0; i < [arrmut count]; i++) {
			NSMutableString *original = [NSMutableString stringWithString: [arrmut objectAtIndex: i]];
			if ([original characterAtIndex: 0] == '"' && [original characterAtIndex: [original length] - 1] == '"') {
				[original deleteCharactersInRange: NSMakeRange(0, 1)];
				[original deleteCharactersInRange: NSMakeRange([original length] - 1, 1)];
			}
		}
		(callback)(arrmut);
	}];
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	NSString *lp = [NSString stringWithFormat: @"%s", git];
	return [self baseTask: lp fromArguments: args];
}

- (void) updateRemote {
	NSArray *arr;
	
	arr = [NSArray arrayWithObjects: @"remote", nil];
	NSTask *t = [self taskFromArguments: arr];
	[tq addTask: t withCallback: ^(NSArray *resarr) {
		NSString *string;
		if (![resarr count])
			return;
		string = [resarr objectAtIndex: 0];
		string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (![string length])
			return;
		
		NSTask *t2 = [self taskFromArguments: [NSArray arrayWithObjects: @"fetch", nil]];
		[tq addTask: t2 withCallback: nil];
	}];
}
	
- (void) getDiffRemoteWithCallback: (void (^)(NSString *)) callback {
	NSArray *arr;
	
	if (!lastRemote) {
		lastRemote = [NSDate date];
		[lastRemote retain];
	} else {
		if ([lastRemote timeIntervalSinceNow] > 3600) {
			[lastRemote release];
			lastRemote = [NSDate date];
			[lastRemote retain];
		} else
			return;
	}
	arr = [NSArray arrayWithObjects: @"remote", nil];
//	NSTask *t = [self taskFromArguments: arr];
	// [tq addTask: t withCallback: ^(NSArray *resultarr) {
	// 	if (![resultarr count]) {
	// 		upstreamMod = NO;
	// 		return nil;
	// 	}
	// 	NSString *string2 = [resultarr objectAtIndex: 0];
	// 	string2 = [string2 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	// 	if (![string2 length]) {
	// 		upstreamMod = NO;
	// 		return nil;
	// 	}
	// 	string2 = [NSString stringWithFormat: @"HEAD...%@", string2];
	// 	NSArray *arr = [NSArray arrayWithObjects: @"diff", @"--shortstat", string2, nil];
	// 	
	// 	NSTask *t = [self taskFromArguments: arr];
	// 	[tq addTask: t withCallback: ^(NSArray *resultarr) {
	// 		if (![resultarr count]) {
	// 			upstreamMod = NO;
	// 			return;
	// 		}
	// 		NSString *string = [resultarr objectAtIndex: 0];
	// 		(callback)([RepoHelper shortenDiff: string]);
	// 	}];	
	// }];
}

- (void) pull: (id) menuItem {
	[mc->commitWindow setTitle: repository];
	[mc->commitWindow makeFirstResponder: mc->tv];

	NSArray *arr = [NSArray arrayWithObjects: @"log", @"HEAD..origin", @"--abbrev-commit", @"--pretty=%h %s", nil];
	NSTask *t = [self taskFromArguments: arr];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		[mc->butt setTitle: @"Update from upstream"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(upstreamUpdate:)];
	
		NSString *string = [resultarr componentsJoinedByString: @"\n"];
		[mc->tv setString: string];
		[mc->tv setEditable: NO];
			
		NSArray *arr = [NSArray arrayWithObjects: @"diff", @"HEAD..origin", nil];
		NSTask *t = [self taskFromArguments: arr];
		[tq addTask: t withCallback: ^(NSArray *resultarr) {
			NSString *string = [resultarr componentsJoinedByString: @"\n"];
			[mc->diffView setString: string];
			[mc->diffView setEditable: NO];
		
			[mc->commitWindow center];
			[NSApp activateIgnoringOtherApps: YES];
			[mc->commitWindow makeKeyAndOrderFront: NSApp];
		}];
	}];
}

- (void) commit: (id) menuItem {
	if (!localMod)
		return;
		
	[mc->commitWindow setTitle: repository];
	[mc->commitWindow makeFirstResponder: mc->tv];

	if (localMod) {	
		[mc->tv setEditable: YES];
		[mc->tv setString: @""];
		[mc->diffView setString: localDiff];
		[mc->butt setTitle: @"Do Commit"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(clickUpdate:)];
	}
	[mc->commitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->commitWindow makeKeyAndOrderFront: NSApp];
	[mc->commitWindow makeFirstResponder: mc->tv];
}

- (void) upstreamUpdate: (id) sender {
	[sender setEnabled: NO];
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"rebase", @"origin", nil]];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		[NSApp hide: self];
		[mc->commitWindow close];
		[sender setEnabled: YES];
		[self fire: nil];
	}];
}

- (void) clickUpdate: (id) button {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"commit", @"-a", @"-m", [[mc->tv textStorage] mutableString], nil]];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		[NSApp hide: self];
		[mc->commitWindow close];
		[self checkLocal: nil];
		[self realFire];
	}];
}

- (void) doLogsForMenu: (NSMenu *)m {
	NSLog(@"doLogsForMenu");
	NSTask *t =
		[self taskFromArguments:
			[NSArray arrayWithObjects: @"log", @"-n", @"10", @"--pretty=format:%h %ar %s", @"--abbrev-commit", nil]];
	[tq addTask: t withCallback: ^(NSArray *logs) {
		NSFont *firstFont = [NSFont userFixedPitchFontOfSize: 16.0];
		NSFont *secondFont = [NSFont userFixedPitchFontOfSize: 12.0];
		NSMenuItem *mi;
	
		if ([logs count] == 1 && [[logs objectAtIndex: 0] isEqualToString: @""]) {
			mi = [[NSMenuItem alloc] initWithTitle: @"No history for this project" action: nil keyEquivalent: @""];
			[m addItem: mi];
		} else {
			int i;
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
					[mi setAttributedTitle: attr];
					[mi autorelease];
					[m addItem: mi];
				}
			}
		}
	}];
}

- (void) noMods {
	//dispatch_sync(dispatch_get_main_queue(), ^{
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
	//});
}

- (void) localModsWithMenu: (NSMenu *)m {
	NSString *sTit;
	[[m insertItemWithTitle: @"Commit these changes" action: @selector(commit:) keyEquivalent: @"" atIndex: [m numberOfItems]]
		setTarget: self];
	if (currentBranch == nil || [currentBranch isEqual: @"master"]) {
		sTit = [NSString stringWithFormat: @"%@: %@",
			[repository lastPathComponent],
			[localDiffSummary stringByTrimmingCharactersInSet:
				[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	} else {
		sTit = [NSString stringWithFormat: @"%@: %@ (%@)",
			[repository lastPathComponent],
			[localDiffSummary stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]], currentBranch];
	}
	[self setTitle: sTit];
	[self setShortTitle: sTit];
	[menuItem setHidden: NO];
}

- (void) setupUpstream {
	NSArray *arr = [NSArray arrayWithObjects: @"remote", nil];
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

- (void) realFire {
	NSArray *untracked;
//	NSString *string;
	
	untracked = [self getUntracked];
	if (untracked && [untracked count]) {
		untrackedFiles = YES;
	} else {
		untrackedFiles = NO;
	}
		
	NSMenu *m = [[NSMenu alloc] initWithTitle: @"Testing"];

	[self doLogsForMenu: m];
	[m insertItem: [NSMenuItem separatorItem] atIndex: [m numberOfItems]];

	if (untrackedFiles) {
		NSString *s = [NSString stringWithFormat: @"%@: %d untracked files", [repository lastPathComponent], [untracked count]];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setTitle: s];
			[self setShortTitle: s];
			[menuItem setHidden: NO];
		});
	} else if (!upstreamMod) {
		if (!localMod) {
			[self noMods];
		} else {
			[self localModsWithMenu: m];
		}
	} else {
		// There is a remote diff.
		NSString *sTit;
		[[m insertItemWithTitle: @"Update From Origin" action: @selector(pull:) keyEquivalent: @"" atIndex: [m numberOfItems]]
			setTarget: self];
//		sTit = [NSString stringWithFormat: @"%@: %@",
//			[repository lastPathComponent],
//			[remoteString stringByTrimmingCharactersInSet:
//				[NSCharacterSet whitespaceAndNewlineCharacterSet]]];

		dispatch_sync(dispatch_get_main_queue(), ^{
			[self setTitle: sTit];
			[self setShortTitle: sTit];
			[menuItem setHidden: NO];
		});
	}
	
	if (localMod)
		[[m insertItemWithTitle: @"Commit" action: @selector(commit:) keyEquivalent: @"" atIndex: [m numberOfItems]]
			setTarget: self];

	if (untrackedFiles)
		[[m insertItemWithTitle: @"Untracked Files" action: @selector(dealWithUntracked:) keyEquivalent: @"" atIndex: [m numberOfItems]]
			setTarget: self];

	[[m insertItemWithTitle: @"Open in Finder" action: @selector(openInFinder:) keyEquivalent: @"" atIndex: [m numberOfItems]]
		setTarget: self];
	[[m insertItemWithTitle: @"Open in Terminal" action: @selector(openInTerminal:) keyEquivalent: @"" atIndex: [m numberOfItems]]
		setTarget: self];
	[[m insertItemWithTitle: @"Ignore" action: @selector(ignore:) keyEquivalent: @"" atIndex: [m numberOfItems]]
		setTarget: self];


	if (untrackedFiles)
		[menuItem setOffStateImage: [BubbleFactory getBlueOfSize: 15]];
	else if (localMod)
		[menuItem setOffStateImage: [BubbleFactory getRedOfSize: 15]];
	else if (upstreamMod)
		[menuItem setOffStateImage: [BubbleFactory getYellowOfSize: 15]];
	else
		[menuItem setOffStateImage: [BubbleFactory getGreenOfSize: 15]];
	[[menuItem offStateImage] autorelease];
	[menuItem setSubmenu: m];
}

@end