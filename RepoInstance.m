#import "RepoInstance.h"
#import "BaseRepositoryType.h"
#import "RepoHelper.h"

@implementation RepoInstance

- initWithRepoType: (BaseRepositoryType *)type shortTitle: (NSString *)title path: (NSString *)path {
	self = [super init];
	_shortTitle = title;
	[_shortTitle retain];
	_repoType = type;
	_data = [[NSMutableDictionary alloc] init];
	_path = path;
	[_path retain];
	return self;
}

- (void)localCommitWindow {
	[[NSNotificationCenter defaultCenter] postNotificationName: @"doCommit" object: self];
}

- (NSString *)shortTitle {
	return _shortTitle;
}

- (NSString *)localDiff {
	return [RepoHelper shortDiff: self];
}

- (void)checkRemoteChanges {
	[_repoType checkRemoteChangesWithRepository: self];
}

- (int) removedLines {
	return [_repoType removedLinesForRepository: self];
}

- (int) addedLines {
	return [_repoType addedLinesForRepository: self];
}

- (int) changedFiles {
	return [_repoType changedFilesForRepository: self];
}

- (void)checkLocalChanges {
	[_repoType checkLocalChangesWithRepository: self];
}

// TODO: This is run every 10 seconds, roughly. It should hold off on the
//       remote changes at least.
- (void)tick {
	if ([self hasRemote]) {
		[self checkRemoteChanges];
	}
	[self checkLocalChanges];
}

- (NSMutableDictionary *)dict {
	return _data;
}

- (BOOL) hasLocal {
	return [_repoType hasLocalWithRepository: self];
}

- (BOOL) hasUntracked {
	return NO;
}

- (BOOL) hasRemote {
	return [_repoType hasRemoteWithRepository: self];
}

- (NSAttributedString *)colorizedDiff {
	return nil;
}

- (NSAttributedString *)colorizedRemoteDiff {
	return nil;
}

- (NSArray *)logs {
	return [_repoType logsWithRepository: self];
}

- (NSArray *)pending {
	return [_repoType pendingWithRepository: self];
}

- (BOOL) logFromToday {
	return [_repoType logFromTodayWithRepository: self];
}

- (NSString *)repository {
	return _path;
}

- (RepoMenuItem *)menuItem {
	return nil;
}

- (void) setMenuItem: (RepoMenuItem *)menuItem {
}

@end