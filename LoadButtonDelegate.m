#import "LoadButtonDelegate.h"

@implementation LoadButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	[super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
}

- (void) setupTimer {
	int delay = [[[NSUserDefaults standardUserDefaults] stringForKey: @"loadDelay"] intValue];
	[self realTimer: delay];
}

- (void) beep: (id) something {
}

- (void) fire {
	double loads[3];
	getloadavg(loads, 3);
	
	NSString *status = [[NSString alloc] initWithFormat: @"Load: %0.2f %0.2f %0.2f", loads[0], loads[1], loads[2]];		
	if (loads[0] < 0.1 && loads[1] < 0.1 && loads[2] < 0.1)
		priority = 6;
	else if (loads[0] < 1.0 && loads[1] < 1.0 && loads[2] < 1.0)
		priority = 14;
	else
		priority = 17;
	
	NSFont *stringFont;
	if (priority <= 10)
		stringFont = [NSFont systemFontOfSize: 9.0];
	else if (priority <= 20)
		stringFont = [NSFont systemFontOfSize: 14.0];
	else
		stringFont = [NSFont systemFontOfSize: 20.0];
	NSDictionary *stringAttributes = [NSDictionary dictionaryWithObject: stringFont forKey: NSFontAttributeName];
	NSAttributedString *lowerString = [[NSAttributedString alloc] initWithString: status attributes: stringAttributes];
	[self setShortTitle: status];
	[self setTitle: status];
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end