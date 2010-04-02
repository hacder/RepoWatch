#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// Switch tasks in a project.

@interface TaskSwitcher : NSObject {
	NSMutableDictionary *oldCommits;
}

@end