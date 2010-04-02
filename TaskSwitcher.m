#import "TaskSwitcher.h"
#import "RepoButtonDelegate.h"

@implementation TaskSwitcher

- (void) doWorkingChange: (NSNotification *)note {
	NSLog(@"doWorkingChange:%@", note);
}

- (void) addCommitMessage: (NSNotification *)note {
	RepoButtonDelegate *rbd = [note object];
	NSString *key = [rbd repository];
	if (![oldCommits objectForKey: key])
		[oldCommits setObject: [NSMutableArray arrayWithCapacity: 1] forKey: key];
	if ([[oldCommits objectForKey: key] containsObject: [[note userInfo] objectForKey: @"commitMessage"]])
		return;
	[[oldCommits objectForKey: key] addObject: [[note userInfo] objectForKey: @"commitMessage"]];
	
	NSLog(@"Old Commits is now %@", oldCommits);
}

- (id) init {
	self = [super init];
	oldCommits = [NSMutableDictionary dictionaryWithCapacity: 10];
	[oldCommits retain];

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(doWorkingChange:) name: @"repoModChange" object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(addCommitMessage:) name: @"repoCommit" object: nil];

	return self;
}

@end