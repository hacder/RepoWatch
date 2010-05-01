#import "GitDiffButtonDelegate.h"
#import "BubbleFactory.h"
#import "RepoHelper.h"
#import "GitRepository.h"

@implementation GitDiffButtonDelegate

- initWithGit: (const char *)gitPath repository: (NSString *)rep {
	git = gitPath;

	self = [super initWithRepositoryName: rep type: [GitRepository sharedInstance]];	
	[self fire: nil];
	return self;
}

- (NSString *)getDiff {
	return @"";
}

- (void) checkUpstream: (NSTimer *)ti {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"fetch", upstreamName, nil]];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		// TODO: Do something sensible with branches.
		NSString *diffString = [NSString stringWithFormat: @"master...%@/master", upstreamName];
		[diffString retain];
		NSArray *arr = [NSArray arrayWithObjects: @"diff", @"--shortstat", diffString, nil];
		NSTask *t = [self taskFromArguments: arr];
		[tq addTask: t withCallback: ^(NSArray *resultarr) {
			[diffString autorelease];
			if ([resultarr count]) {
				upstreamMod = YES;
				[remoteDiffStat autorelease];
				remoteDiffStat = [RepoHelper shortenDiff: [resultarr objectAtIndex: 0]];
				[remoteDiffStat retain];
				
				NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"diff", diffString, nil]];
				[tq addTask: t withCallback: ^(NSArray *resultarr) {
					[remoteDiff autorelease];
					remoteDiff = [RepoHelper colorizedDiffFromArray: resultarr];
					[remoteDiff retain];
				}];				
			} else {
				upstreamMod = NO;
				[remoteDiffStat autorelease];
				remoteDiffStat = nil;
			}
			[super checkUpstream: ti];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"updateTitle" object: self];
		}];
	}];
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
		NSRange range01 = NSMakeRange(0, 1);
		for (i = 0; i < [arrmut count]; i++) {
			NSMutableString *original = [NSMutableString stringWithString: [arrmut objectAtIndex: i]];
			if ([original characterAtIndex: 0] == '"' && [original characterAtIndex: [original length] - 1] == '"') {
				[original deleteCharactersInRange: range01];
				[original deleteCharactersInRange: NSMakeRange([original length] - 1, 1)];
				[arrmut replaceObjectAtIndex: i withObject: original];
			}
		}
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

- (void)getUntrackedWithCallback: (void (^)(NSArray *)) callback {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"ls-files", @"--others", @"--exlcude-standard", @"-z", nil]];
	[tq addTask: t withCallback: ^(NSArray *arr) {
		NSMutableArray *arrmut = [NSMutableArray arrayWithArray: arr];
		int i;
		NSRange range01 = NSMakeRange(0, 1);
		for (i = 0; i < [arrmut count]; i++) {
			NSMutableString *original = [NSMutableString stringWithString: [arrmut objectAtIndex: i]];
			if ([original characterAtIndex: 0] == '"' && [original characterAtIndex: [original length] - 1] == '"') {
				[original deleteCharactersInRange: range01];
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
				} else {
					upstreamURL = nil;
				}
				[self checkUpstream: nil];
			}];
		} else {
			upstreamName = nil;
		}
	}];
}

- (NSString *)shortTitle {
	if (localMod) {
		return [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], localDiffSummary];
	} else if (upstreamMod) {
		return [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], remoteDiffStat];
	} else {
		if (repository)
			return [repository lastPathComponent];
		return @"";
	}
}

@end