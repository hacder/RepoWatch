#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class MainController;

@interface ButtonDelegate : NSObject {
	NSMenu *menu;
	NSStatusItem *statusItem;
	MainController *mc;
@public
	NSString *shortTitle;
	NSMenuItem *menuItem;
	NSString *title;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc;
- (void) fire: (NSTimer *)t;
- (void) addMenuItem;
- (NSString *) shortTitle;
- (void) setShortTitle: (NSString *)t;
- (void) setTitle: (NSString *)t;
- (NSMenuItem *) getMenuItem;
- (void) beep: (id) something;

@end