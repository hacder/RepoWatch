#import "SeparatorButtonDelegate.h"

@implementation SeparatorButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	[self setPriority: -99];
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