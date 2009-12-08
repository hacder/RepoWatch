#import "RepoButtonDelegate.h"
#import <dispatch/dispatch.h>
#import <sys/time.h>

@implementation RepoButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mc];
	[self setPriority: 0];
	return self;
}

- (void) beep: (id) something {
}

- (void) fire {
}

- (void) setPriority: (int) p {
	if (priority == p)
		return;
	priority = p;
}

@end