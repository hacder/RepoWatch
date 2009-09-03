#import "SeparatorButtonDelegate.h"

@implementation SeparatorButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	[super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
}

- (void) addMenuItem {
	menuItem = [NSMenuItem separatorItem];
	[menu insertItem: menuItem atIndex: [menu numberOfItems]];
	[menuItem setTarget: self];
	priority = -99;
}

- (void) setupTimer {
}

- (void) beep: (id) something {
}

- (void) fire: (NSTimer *)t {
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end