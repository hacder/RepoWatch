#import "ODeskButtonDelegate.h"
#import <dispatch/dispatch.h>

@implementation ODeskButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	[self setupTimer];
	return self;
}

- (void) beep: (id) something {
}

- (void) fire {
}

@end