#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// A very simple wrapper around an array. More utility methods will be added once this
// class actually starts to be used.


@interface DiffSet : NSObject {
	NSArray *diffs; // Array of Diff objects
}

- init;

@end