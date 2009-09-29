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
	NSView *_prefView;
	dispatch_source_t timer;
@public
	int priority;
	int timeout;
	NSString *title;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc;
- (void) fire;
- (void) setupTimer;
- (void) addMenuItem;
- (void) forceRefresh;
- (NSString *) shortTitle;
- (void) setShortTitle: (NSString *)t;
- (void) setTitle: (NSString *)t;
- (void) setHidden: (BOOL)b;
- (void) setPriority: (int) p;
- (NSView *) preferences;

@end