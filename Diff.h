#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "FileDiff.h"

// A class that I want to start using, but that isn't used at all right now, which contains information
// about a single changeset. Most of the information is contained in the files array.

@interface Diff : NSObject <NSTableViewDataSource> {
	FileDiff *file;
	NSArray *lines;
	int countAdded;
	int countRemoved;
}

- init;
- (void) setLines: (NSArray *)lines;
- (void) setFile: (FileDiff *)file;
- (int) numAdded;
- (int) numRemoved;


@end