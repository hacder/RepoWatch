#import "TaskSwitcher.h"

@implementation TaskSwitcher

- (void) doWorkingChange: (NSNotification *)note {
	NSLog(@"doWorkingChange:%@", note);
}

- (void) addCommitMessage: (NSNotification *)note {
	NSLog(@"repoCommit: %@", note);
}

- (id) init {
	self = [super init];

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(doWorkingChange:) name: @"repoModChange" object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(addCommitMessage:) name: @"repoCommit" object: nil];

	NSLog(@"TaskSwitcher init");
	return self;
}

@end