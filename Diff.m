#import "Diff.h"

@implementation Diff

- init {
	self = [super init];
	files = [NSMutableArray arrayWithCapacity: 10];
	[files retain];
	backingStore = [NSMutableArray arrayWithCapacity: 10];
	[backingStore retain];
	lock = [[NSLock alloc] init];
	return self;
}

- (void) start {
	[lock lock];
	[backingStore removeAllObjects];
	[lock unlock];
}

- (void) flip {
	[lock lock];
	if ([files isEqualToArray: backingStore])
		[[NSNotificationCenter defaultCenter] postNotificationName: @"localFilesChange" object: self];
		
	NSMutableArray *tmp = backingStore;
	backingStore = files;
	files = tmp;
	[lock unlock];
}

- (void) addFile: (NSString *)fileName {
	[lock lock];
	[backingStore addObject: fileName];
	[lock unlock];
}

- (int) numberOfRowsInTableView: (NSTableView *)tv {
	[lock lock];
	int ret = [files count];
	[lock unlock];
	return ret;
}

- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)col row: (NSInteger)r {
	[lock lock];
	id ret = nil;
	if ([files count] > r)
		ret = [files objectAtIndex: r];
	[lock unlock];
	return ret;
}



@end