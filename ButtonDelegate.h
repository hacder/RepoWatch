#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"

@interface ButtonDelegate : NSObject {
	NSMenuItem *menuItem;
	NSString *shortTitle;
	NSMenu *menu;
	NSStatusItem *statusItem;
	MainController *mainController;
	NSView *_prefView;
	dispatch_source_t timer;
@public
	int timeout;
	NSString *title;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc;
- (void) fire;
- (void) setupTimer;
- (void) addMenuItem;
- (NSString *) shortTitle;
- (void) setShortTitle: (NSString *)t;
- (void) setTitle: (NSString *)t;
- (void) setHidden: (BOOL)b;

@end