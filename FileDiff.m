#import "FileDiff.h"
#import "Diff.h"

@implementation FileDiff

- init {
	self = [super init];
	hunks = [NSMutableArray arrayWithCapacity: 10];
	[hunks retain];
	return self;
}

- (id) copyWithZone: (NSZone *)z {
	return NSCopyObject(self, 0, z);
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

- (void) setIncluded: (BOOL)i {
	included = i;
}

- (BOOL) getIncluded {
	return included;
}

- (RepoInstance *)repo {
	return repoInstance;
}

- (void) setLines: (NSArray *)l {
	[lines autorelease];
	lines = l;
	[lines retain];
	[hunks removeAllObjects];
	
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
			
			// Hunk just started!
			d = [[Diff alloc] init];
			[d setFile: self];
			[hunks addObject: d];
		} else {
			[arr addObject: curline];
		}
	}
	[d setLines: arr];
}

- (NSString *)fileName {
	return fn;
}

- (void) setFileName: (NSString *)fileName {
	[fn autorelease];
	fn = fileName;
	[fn retain];
}

- (void) setRepo: (RepoInstance *)ri {
	[repoInstance autorelease];
	repoInstance = ri;
	[repoInstance retain];
}

@end