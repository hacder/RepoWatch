#import "RepoList.h"

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
	NSLog(@"RepoList now has %d objects", [list count]);
}

- init {
	self = [super init];
	list = [NSMutableArray arrayWithCapacity: 0];
	[list retain];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(repoFound:) name: @"repoFound" object: nil];
	return self;
}

@end