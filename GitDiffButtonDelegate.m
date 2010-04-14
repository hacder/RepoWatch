#import "GitDiffButtonDelegate.h"
#import "BubbleFactory.h"
#import "RepoHelper.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s gitPath: (char *)gitPath repository: (NSString *)rep {
	git = gitPath;
	self = [super initWithTitle: s repository: rep];
	
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
	}];
}

// A git mailing list person said that to get untracked you would write
// git ls-files -t -m -o --exclude-standard
// our addition of -z looks sane, as it just changes what the lines are terminated with
// -t and -m both are truly missing from ours. -m especially seems misleading.
- (void) checkUntracked {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"ls-files", @"--others", @"--exclude-standard", @"-z", nil]];
	[tq addTask: t withCallback: ^(NSArray *arr) {
		if (![arr count]) {
			[self setUntracked: NO];
			return;
		}
		[self setUntracked: YES];

		NSMutableArray *arrmut = [NSMutableArray arrayWithArray: arr];
		int i;
		for (i = 0; i < [arrmut count]; i++) {
			NSMutableString *original = [NSMutableString stringWithString: [arrmut objectAtIndex: i]];
			if ([original characterAtIndex: 0] == '"' && [original characterAtIndex: [original length] - 1] == '"') {
				[original deleteCharactersInRange: NSMakeRange(0, 1)];
				[original deleteCharactersInRange: NSMakeRange([original length] - 1, 1)];
				[arrmut replaceObjectAtIndex: i withObject: original];
			}
		}
		NSLog(@"Untracked: %@", arrmut);
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
			[self setDirty: NO];
			return;
		}
		NSString *newSummary = [RepoHelper shortenDiff: [resultarr objectAtIndex: 0]];
		if (localDiffSummary != nil) {
			if ([newSummary caseInsensitiveCompare: localDiffSummary] == NSOrderedSame) {
				// The summary did not change. The details might have, though, so we can't completely short-circuit.
			} else {
				[localDiffSummary autorelease];
				localDiffSummary = [RepoHelper shortenDiff: [resultarr objectAtIndex: 0]];
				[localDiffSummary retain];
				[[NSNotificationCenter defaultCenter] postNotificationName: @"updateTitle" object: self];		
			}
		} else {
			// Repeated code. BAD.
			[localDiffSummary autorelease];
			localDiffSummary = [RepoHelper shortenDiff: [resultarr objectAtIndex: 0]];
			[localDiffSummary retain];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"updateTitle" object: self];					
		}
		[self setLocalMod: YES];
 		
		NSArray *arr = [NSArray arrayWithObjects: @"diff", nil];
		NSTask *t = [self taskFromArguments: arr];
		[tq addTask: t withCallback: ^(NSArray *resultarr) {
			[localDiff autorelease];
			localDiff = [RepoHelper colorizedDiffFromArray: resultarr];
			[localDiff retain];
			[super checkLocal: ti];
		}];
	}];
}

- (void) addAll: (id) button {
	int i;
	for (i = 0; i < [currentUntracked count]; i++) {
		NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"add", [currentUntracked objectAtIndex: i], nil]];
		[tq addTask: t withCallback: nil];
	}
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

- (NSArray *)logs {
	NSArray *arr = [NSArray arrayWithObjects: @"log", @"-n", @"10", @"--pretty=%h %ct %s", nil];
	NSTask *t = [self taskFromArguments: arr];

	NSFileHandle *file = [RepoHelper pipeForTask: t];
	NSFileHandle *err = [RepoHelper errForTask: t];

	[t launch];
	NSString *string = [RepoHelper stringFromFile: file];
	NSArray *result = [string componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\0"]];
	[t waitUntilExit];
	if ([t terminationStatus] != 0) {
		return nil;
	}
	[err closeFile];
	[file closeFile];

	if ([[result objectAtIndex: [result count] - 1] isEqualToString: @""]) {
		NSMutableArray *result2 = [NSMutableArray arrayWithArray: result];
		[result2 removeObjectAtIndex: [result2 count] - 1];
		return result2;
	}

	return result;
}

- (void) pull: (id) menuItem {
	NSArray *arr = [NSArray arrayWithObjects: @"log", @"HEAD..origin", @"--abbrev-commit", @"--pretty=%h %s", nil];
	NSTask *t = [self taskFromArguments: arr];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		NSArray *arr = [NSArray arrayWithObjects: @"diff", @"HEAD..origin", nil];
		NSTask *t = [self taskFromArguments: arr];
		[tq addTask: t withCallback: ^(NSArray *resultarr) {
			[NSApp activateIgnoringOtherApps: YES];
		}];
	}];
}

- (void) commit: (id) mi {
	if (!localMod)
		return;
	
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"commit", @"-a", @"-m", commitMessage, nil]];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"commitStart" object: self];		
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		[self setLocalMod: NO];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"commitDone" object: self];		
	}];
}

- (void) upstreamUpdate: (id) sender {
	[sender setEnabled: NO];
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"rebase", @"origin", nil]];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		[NSApp hide: self];
		[sender setEnabled: YES];
		[self fire: nil];
	}];
}

- (void) clickUpdate: (id) button {
}

- (void) setupUpstream {
	NSArray *arr = [NSArray arrayWithObjects: @"remote", nil];
	NSTask *t = [self taskFromArguments: arr];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		if ([resultarr count]) {
			upstreamName = [resultarr objectAtIndex: 0];
			[upstreamName retain];
			
			NSArray *arr = [NSArray arrayWithObjects: @"config", [NSString stringWithFormat: @"remote.%@.url", upstreamName], nil];
			NSTask *t = [self taskFromArguments: arr];
			[tq addTask: t withCallback: ^(NSArray *resultarr) {
				if ([resultarr count]) {
					upstreamURL = [resultarr objectAtIndex: 0];
					[upstreamURL retain];
					NSLog(@"Upstream URL is %@", upstreamURL);
				} else {
					upstreamURL = nil;
				}
			}];
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

@end