#import "TimeButtonDelegate.h"

@implementation TimeButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	timeout = 1;
	[self setHidden: YES];
	[self setupTimer];
	return self;
}

- (void) beep: (id) something {
}

- (void) fire {
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat: @"EEE h:mm a"];
	NSDate *date = [NSDate date];
	NSString *formattedString = [dateFormatter stringFromDate: date];
	
	[self setShortTitle: formattedString];
	[self setTitle: formattedString];
	[self setHidden: NO];
	[self setPriority: 20];
}

@end