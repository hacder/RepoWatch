#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// A class representing a changeset to a single file.

@interface FileDiff : NSObject {
	NSString *fn;
	NSArray *lines;
	NSMutableArray *hunks;
}

- init;
- (void) setLines: (NSArray *)lines;
- (void) setFileName: (NSString *)fileName;
- (int) numHunks;
- (int) numAdded;
- (int) numRemoved;
- (NSString *) fileName;

@end