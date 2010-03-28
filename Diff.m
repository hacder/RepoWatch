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


@end