#import "CommitWindowController.h"

@implementation CommitWindowController

- (id) init {
	self = [super init];

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(doCommit:) name: @"doCommit" object: nil];
	cell = [[FileDiffListCell alloc] initTextCell: @"poop"];
	[cell setBordered: NO];
	[cell setBezeled: NO];
	return self;
}

- (void) awakeFromNib {
	[commitWindow center];

	NSTableColumn *column = [[changedFilesTable tableColumns] objectAtIndex:0];
	[column setDataCell: cell];
}

- (void) doCommit: (NSNotification *)notif {
	currentRepo = [notif object];
	
	[changedFilesTable setDataSource: self];
	
	[commitWindow makeKeyAndOrderFront: self];
	[NSApp activateIgnoringOtherApps: YES];
}

- (NSInteger) numberOfRowsInTableView: (NSTableView *)aTableView {
	return [currentRepo changedFiles];
}

- (id) tableView: (NSTableView *)aTableView objectValueForTableColumn: (NSTableColumn *)aTableColumn row: (NSInteger)rowIndex {
	return [[[currentRepo dict] objectForKey: @"diffs"] objectAtIndex: rowIndex];
}

@end