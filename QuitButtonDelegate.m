#import "QuitButtonDelegate.h"

@implementation QuitButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	priority = -101;
	return self;
}

- (void) setupTimer {
}

- (void) beep: (id) something {
	[NSApp terminate: self];
}

- (void) fire {
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end