#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// The Button Delegate is the core class for items that appear in menus and handle clicks, etc.
// Its main subclass is RepoButtonDelegate. In fact, RepoButtonDelegate is the ONLY subclass that
// I don't want to retire. This class and RepoButtonDelegate are due to be folded into one, better
// named, class.

@class MainController;

@interface ButtonDelegate : NSObject {
	NSString *shortTitle;
	NSString *title;
}

- (void) fire: (NSTimer *)t;
- (NSString *) shortTitle;
- (void) setShortTitle: (NSString *)t;
- (void) beep: (id) something;

@end