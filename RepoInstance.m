#import "RepoInstance.h"
#import "BaseRepositoryType.h"

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

- (NSString *)shortTitle {
	if ([_repoType respondsToSelector: @selector(shortTitle:)]) {
		return [_repoType performSelector: @selector(shortTitle:) withObject: _shortTitle];
	}
	return _shortTitle;
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