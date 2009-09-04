#import "QuitButtonDelegate.h"

@implementation QuitButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	[super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	priority = -101;
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