#import "Diff.h"

@implementation Diff

- init {
	self = [super init];
	countAdded = 0;
	countRemoved = 0;
	return self;
}

- (int) numAdded {
	return countAdded;
}

- (int) numRemoved {
	return countRemoved;
}

- (void) setLines: (NSArray *)l {
	[lines autorelease];
	lines = l;
	[lines retain];
	
	countAdded = 0;
	countRemoved = 0;
	
	int i;
	for (i = 0; i < [lines count]; i++) {
		NSString *curline = [lines objectAtIndex: i];
		NSRange r = [curline rangeOfString: @"+"];
		if (r.location == 0)
			countAdded++;
		r = [curline rangeOfString: @"-"];
			countRemoved++;
	}
}

- (void) setFile: (FileDiff *)f {
	[file autorelease];
	file = f;
	[file retain];
}

@end