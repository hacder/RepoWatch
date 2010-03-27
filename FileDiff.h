#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// A class representing a changeset to a single file.

@interface FileDiff : NSObject {
	NSString *fileName;
	NSString *diff;
}

- init;

@end