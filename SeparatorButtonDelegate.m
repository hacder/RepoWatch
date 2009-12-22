#import "SeparatorButtonDelegate.h"

@implementation SeparatorButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc];
	return self;
}

- (void) addMenuItem {
	menuItem = [NSMenuItem separatorItem];
	[menu insertItem: menuItem atIndex: [menu numberOfItems]];
	[menuItem setTarget: self];
}

- (void) setupTimer {
}

- (void) beep: (id) something {
}

@end