#import "RepoList.h"
#import "RepoInstance.h"

@implementation RepoList

RepoList *sharedRepoList;

+ (RepoList *)sharedInstance {
	if (!sharedRepoList)
		sharedRepoList = [[RepoList alloc] init];
	return sharedRepoList;
}

- (void) repoFound: (NSNotification *)notification {
	if ([notification object])
		[list addObject: [notification object]];
}

- init {
	self = [super init];
	list = [NSMutableArray arrayWithCapacity: 0];
	[list retain];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(repoFound:) name: @"repoFound" object: nil];
	return self;
}

- (NSInteger) numberRecentRepositories {
	NSInteger ret = 0;
	int i;
	for (i = 0; i < [list count]; i++) {
		RepoInstance *ri = [list objectAtIndex: i];
		if ([ri logFromToday])
			ret++;
	}
	return ret;
}

- (NSArray *) recentRepositories {
	NSMutableArray *ret = [NSMutableArray arrayWithCapacity: [list count]];
	int i;
	for (i = 0; i < [list count]; i++) {
		RepoInstance *ri = [list objectAtIndex: i];
		if ([ri logFromToday])
			[ret addObject: ri];
	}
	return ret;
}

@end