#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ButtonDelegate.h"

@interface LoadButtonDelegate : ButtonDelegate {
	IBOutlet id _highLoad;
	IBOutlet id _mediumLoad;
	IBOutlet id _highPriority;
	IBOutlet id _mediumPriority;
	IBOutlet id _lowPriority;
}

@end