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
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		[self setLocalMod: NO];
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