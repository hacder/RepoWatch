#import "CommitWindowController.h"

@implementation CommitWindowController

- (id) init {
	self = [super init];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(doCommit:) name: @"doCommit" object: nil];
	return self;
}

- (void) doCommit: (NSNotification *)notif {
	currentRepo = [notif object];
	
	[changedFilesTable setDataSource: self];
	
	[commitWindow center];
	[commitWindow makeKeyAndOrderFront: self];
	[NSApp activateIgnoringOtherApps: YES];
}

- (NSInteger) numberOfRowsInTableView: (NSTableView *)aTableView {
	return [currentRepo changedFiles];
}

- (id) tableView: (NSTableView *)aTableView objectValueForTableColumn: (NSTableColumn *)aTableColumn row: (NSInteger)rowIndex {
	return [[[[[currentRepo dict] objectForKey: @"diffs"] objectAtIndex: rowIndex] fileName] lastPathComponent];
}

@end