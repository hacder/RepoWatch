#import "QuitButtonDelegate.h"

@implementation QuitButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mc];
	return self;
}

- (void) beep: (id) something {
	[NSApp terminate: self];
}

@end