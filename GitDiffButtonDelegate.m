#import "GitDiffButtonDelegate.h"
#import "BubbleFactory.h"
#import "RepoHelper.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s mainController: (MainController *)mcc gitPath: (char *)gitPath repository: (NSString *)rep {
	git = gitPath;
	self = [super initWithTitle: s mainController: mcc repository: rep];
	
	diffCommitTV = mc->diffCommitTextView;
	[diffCommitTV retain];
	
	[self fire: nil];
	return self;
}

- (void) doFileDiff {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"diff-files", @"--name-only", nil]];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		if (!currLocalDiff) {
			currLocalDiff = [[Diff alloc] init];
			[currLocalDiff retain];
		}
		int i;
		[currLocalDiff start];
		for (i = 0; i < [resultarr count]; i++) {
			[currLocalDiff addFile: [resultarr objectAtIndex: i]];
		}
		[currLocalDiff flip];
		if ([mc->fileList dataSource] == currLocalDiff)
			[mc->fileList reloadData];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"localFilesChange" object: self];
	}];
}

- (void) checkLocal: (NSTimer *)ti {
	if (!dirty) {
		[super checkLocal: ti];
		return;
	}
	[self doFileDiff];
	
	NSArray *arr = [NSArray arrayWithObjects: @"diff", @"--shortstat", @"HEAD", nil];
	NSTask *t = [self taskFromArguments: arr];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		if (![resultarr count]) {
			[self setLocalMod: NO];
			[localDiffSummary autorelease];
			localDiffSummary = nil;
			[localDiff autorelease];
			localDiff = nil;
			[super checkLocal: ti];
			[self realFire];
			[self setDirty: NO];
			return;
		}
		[localDiffSummary autorelease];
		localDiffSummary = [RepoHelper shortenDiff: [resultarr objectAtIndex: 0]];
		[localDiffSummary retain];
		[self setLocalMod: YES];
 		
		NSArray *arr = [NSArray arrayWithObjects: @"diff", nil];
		NSTask *t = [self taskFromArguments: arr];
		[tq addTask: t withCallback: ^(NSArray *resultarr) {
			[localDiff autorelease];
			localDiff = [RepoHelper colorizedDiffFromArray: resultarr];
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
	// 		[self setUpstreamMod: NO];
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

- (void) commit: (id) mi {
	if (!localMod)
		return;

	[super commit: mi];

	if (localMod) {	
		[mc->tv setEditable: YES];
		[mc->tv setString: @""];

		// Insert text is the only method that is documented to take an attributed string.
		[[mc->diffView textStorage] setAttributedString: localDiff];
		[mc->diffView scrollRangeToVisible: NSMakeRange(0, 0)];
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
	NSString *commitMessage = [[mc->tv textStorage] string];

	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"commit", @"-a", @"-m", commitMessage, nil]];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"repoCommit" object: self userInfo: [NSDictionary dictionaryWithObjectsAndKeys: commitMessage, @"commitMessage", nil]];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		[NSApp hide: self];
		[mc->commitWindow close];
		[self checkLocal: nil];
		[self realFire];
	}];
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

- (NSString *)shortTitle {
	if (localMod) {
		return [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], localDiffSummary];
	} else {
		return [repository lastPathComponent];
	}
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
		
	if (untrackedFiles) {
		NSString *s = [NSString stringWithFormat: @"%@: %d untracked files", [RepoHelper makeNameFromRepo: self], [untracked count]];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setTitle: s];
			[self setShortTitle: s];
			[menuItem setHidden: NO];
		});
	} else if (!upstreamMod) {
	} else {
		// There is a remote diff.
		NSString *sTit;
//		sTit = [NSString stringWithFormat: @"%@: %@",
//			[repository lastPathComponent],
//			[remoteString stringByTrimmingCharactersInSet:
//				[NSCharacterSet whitespaceAndNewlineCharacterSet]]];

		dispatch_async(dispatch_get_main_queue(), ^{
			[self setTitle: sTit];
			[self setShortTitle: sTit];
			[menuItem setHidden: NO];
		});
	}
}

@end