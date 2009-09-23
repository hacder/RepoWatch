#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

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

@end