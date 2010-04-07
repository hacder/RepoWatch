#import "QuitButtonDelegate.h"

@implementation QuitButtonDelegate

- initWithTitle: (NSString *)s mainController: (MainController *)mcc {
	self = [super initWithTitle: s mainController: mcc];
	return self;
}

- (void) beep: (id) something {
	[NSApp terminate: self];
}

@end