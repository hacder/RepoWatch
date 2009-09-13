#import "LoadButtonDelegate.h"

@implementation LoadButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	[super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
}

- (void) setupTimer {
	int delay = [[[NSUserDefaults standardUserDefaults] stringForKey: @"loadDelay"] intValue];
	[self realTimer: delay];
}

- (NSView *) preferences {
	if (_prefView != nil)
		return _prefView;
	
	// Need better way to handle this?
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		NSLog(@"No! Load button asked for its preferences from queue %s", dispatch_queue_get_label(dispatch_get_current_queue()));
		return nil;
	}

	NSNib *loadNib = [[NSNib alloc] initWithNibNamed: @"load" bundle: nil];
	[loadNib retain];
	NSArray *arr2;
	[loadNib instantiateNibWithOwner: self topLevelObjects: &arr2];
	NSLog(@"Pref view objects: %@\n", arr2);
		
	_prefView = [arr2 objectAtIndex: 1];
	[_prefView retain];
	return _prefView;
}

- (void) beep: (id) something {
}

- (void) fire {
	double loads[3];
	getloadavg(loads, 3);
	
	NSString *status = [[NSString alloc] initWithFormat: @"Load: %0.2f %0.2f %0.2f", loads[0], loads[1], loads[2]];		
	if (loads[0] < 0.1 && loads[1] < 0.1 && loads[2] < 0.1)
		priority = 6;
	else if (loads[0] < 1.0)
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