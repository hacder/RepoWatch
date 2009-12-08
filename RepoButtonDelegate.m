#import "RepoButtonDelegate.h"
#import <dispatch/dispatch.h>
#import <sys/time.h>

@implementation RepoButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mc];
	localMod = NO;
	upstreamMod = NO;
	return self;
}

- (void) beep: (id) something {
}

- (void) fire {
}

@end