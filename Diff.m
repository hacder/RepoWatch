#import "Diff.h"

@implementation Diff

- init {
	self = [super init];
	files = [NSMutableArray arrayWithCapacity: 10];
	[files retain];
	backingStore = [NSMutableArray arrayWithCapacity: 10];
	[backingStore retain];
	return self;
}

- (void) start {
	[backingStore removeAllObjects];
}

- (void) flip {
	if ([files isEqualToArray: backingStore])
		[[NSNotificationCenter defaultCenter] postNotificationName: @"localFilesChange" object: self];
		
	NSMutableArray *tmp = backingStore;
	backingStore = files;
	files = tmp;
}

- (void) addFile: (NSString *)fileName {
	[backingStore addObject: fileName];
}

- (int) numberOfRowsInTableView: (NSTableView *)tv {
	return [files count];
}

- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)col row: (NSInteger)r {
	return [files objectAtIndex: r];
}



@end