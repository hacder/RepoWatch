#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"

@interface ButtonDelegate : NSObject {
	NSMenuItem *menuItem;
	NSString *script;
	NSString *shortTitle;
	NSTask *task;
	NSMenu *menu;
	NSStatusItem *statusItem;
	MainController *mainController;
@public
	NSString *title;
	int priority;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc;
- (NSString *)runScriptWithArgument: (NSString *)arg;
- (void) fire: (NSTimer *)t;
- (void) setupTimer;
- (void) addMenuItem;
- (void) forceRefresh;
- (NSString *) shortTitle;
- (void) setShortTitle: (NSString *)t;
- (void) setTitle: (NSString *)t;
- (void) setHidden: (BOOL)b;

@end