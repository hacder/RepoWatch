#import "CommitWindowController.h"

@implementation CommitWindowController

- (id) init {
	self = [super init];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(doCommit:) name: @"doCommit" object: nil];
	return self;
}

- (void) doCommit: (NSNotification *)notif {
	[commitWindow center];
	[commitWindow makeKeyAndOrderFront: self];
	[NSApp activateIgnoringOtherApps: YES];
}

@end