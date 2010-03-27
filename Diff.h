#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// A class that I want to start using, but that isn't used at all right now, which contains information
// about a single changeset. Most of the information is contained in the files array.

@interface Diff : NSObject {
	NSString *hash;
	NSString *author;
	NSDate *ts;
	NSArray *files; // Array of FileDiff objects
}

- init;

@end