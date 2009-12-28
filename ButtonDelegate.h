#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"

@interface ButtonDelegate : NSObject {
	NSMenuItem *menuItem;
	NSString *shortTitle;
	NSMenu *menu;
	NSStatusItem *statusItem;
	MainController *mc;
	NSView *_prefView;
@public
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