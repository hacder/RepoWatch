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
	BOOL ignore;
@public
	int priority;
	NSString *title;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc;
- (NSString *)runScriptWithArgument: (NSString *)arg;
- (void) fire;
- (void) setupTimer;
- (void) addMenuItem;
- (void) forceRefresh;
- (NSString *) shortTitle;
- (void) setShortTitle: (NSString *)t;
- (void) setTitle: (NSString *)t;
- (void) setHidden: (BOOL)b;
- (void) realTimer: (int)t;
- (void) setPriority: (int) p;
- (NSView *) preferences;

@end