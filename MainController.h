#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ButtonDelegate;

@interface MainController : NSObject {
	NSStatusItem *statusItem;
	NSMenu *theMenu;
	NSMutableArray *plugins;
}

- init;
- (void) initWithDirectory: (NSString *)dir;
- (void) addDir: (NSString *)dir;
- (void) reset;
- (void) maybeRefresh: (ButtonDelegate *)bd;

@end