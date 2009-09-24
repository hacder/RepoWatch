#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ButtonDelegate;

@interface MainController : NSObject {
	NSStatusItem *statusItem;
	NSMenu *theMenu;
	NSMutableArray *plugins;
}

- init;
- initWithDirectory: (NSString *)s;
- addDir: (NSString *)s;
- (void) rearrange;
- (void) reset;
- (void) maybeRefresh: (ButtonDelegate *)bd;

@end