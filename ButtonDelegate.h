#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class MainController;

@interface ButtonDelegate : NSObject {
	NSString *shortTitle;
	NSMenu *menu;
	NSStatusItem *statusItem;
	MainController *mc;
	NSView *_prefView;
@public
	NSMenuItem *menuItem;
	NSString *title;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc;
- (void) fire;
- (void) addMenuItem;
- (NSString *) shortTitle;
- (void) setShortTitle: (NSString *)t;
- (void) setTitle: (NSString *)t;
- (NSMenuItem *) getMenuItem;
- (void) beep: (id) something;

@end