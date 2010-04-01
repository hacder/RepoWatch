#import "Diff.h"

@implementation Diff

- init {
	self = [super init];
	files = [NSMutableArray arrayWithCapacity: 10];
	[files retain];
	return self;
}

- (void) addFile: (NSString *)fileName {
	[files addObject: fileName];
}

- (int) numberOfRowsInTableView: (NSTableView *)tv {
	return [files count];
}

- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)col row: (NSInteger)r {
	return [files objectAtIndex: r];
}



@end