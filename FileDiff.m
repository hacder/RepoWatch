#import "FileDiff.h"
#import "Diff.h"

@implementation FileDiff

- init {
	self = [super init];
	hunks = [NSMutableArray arrayWithCapacity: 10];
	[hunks retain];
	NSLog(@"\tCreating FileDiff: %@", self);
	return self;
}

- (int) numHunks {
	return [hunks count];
}

- (int) numAdded {
	int i;
	int tot = 0;
	
	for (i = 0; i < [hunks count]; i++) {
		tot += [[hunks objectAtIndex: i] numAdded];
	}
	return tot;
}

- (int) numRemoved {
	int i;
	int tot = 0;
	
	for (i = 0; i < [hunks count]; i++) {
		tot += [[hunks objectAtIndex: i] numRemoved];
	}
	return tot;
}

- (void) setLines: (NSArray *)l {
	[lines autorelease];
	lines = l;
	[lines retain];
	[hunks removeAllObjects];
	
	NSLog(@"\tFileDiff->setLines");
	
	Diff *d = nil;
	NSMutableArray *arr = nil;
	
	int i;
	for (i = 0; i < [lines count]; i++) {
		NSString *curline = [lines objectAtIndex: i];
		NSRange r = [curline rangeOfString: @"@@ "];
		if (r.location == 0) {
			if (d) {
				[d setLines: arr];
			}
			arr = [NSMutableArray arrayWithCapacity: 10];
			
			NSLog(@"\t\tFileDiff->setLines create Diff object");
			// Hunk just started!
			d = [[Diff alloc] init];
			[d setFile: self];
			[hunks addObject: d];
		} else {
			[arr addObject: curline];
		}
	}
	[d setLines: arr];
	NSLog(@"\tFileDiff->setLines over");
}

- (void) setFileName: (NSString *)fn {
	[fileName autorelease];
	fileName = fn;
	[fileName retain];
}

@end