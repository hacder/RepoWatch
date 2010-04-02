#import "TaskSwitcher.h"
#import "RepoButtonDelegate.h"

@implementation TaskSwitcher

- (void) addCommitMessage: (NSNotification *)note {
	RepoButtonDelegate *rbd = [note object];
	NSString *key = [rbd repository];
	if (![oldCommits objectForKey: key])
		[oldCommits setObject: [NSMutableArray arrayWithCapacity: 1] forKey: key];
	if ([[oldCommits objectForKey: key] containsObject: [[note userInfo] objectForKey: @"commitMessage"]])
		return;
	[[oldCommits objectForKey: key] addObject: [[note userInfo] objectForKey: @"commitMessage"]]; 
}

- (id) init {
	self = [super init];
	oldCommits = [NSMutableDictionary dictionaryWithCapacity: 10];
	[oldCommits retain];

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(addCommitMessage:) name: @"repoCommit" object: nil];

	return self;
}

- (void) showWindow {
	NSLog(@"Got here...");
	[taskSwitcherWindow makeKeyAndOrderFront: NSApp];
}

@end