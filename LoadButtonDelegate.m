#import "LoadButtonDelegate.h"

@implementation LoadButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	return self;
}

- (void) setupTimer {
	int delay = [[[NSUserDefaults standardUserDefaults] stringForKey: @"loadDelay"] intValue];
	[self realTimer: delay];
}

- (NSView *) preferences {
	if (_prefView != nil)
		return _prefView;
	
	// Need better way to handle this?
	if (dispatch_get_current_queue() != dispatch_get_main_queue())
		return nil;

	NSNib *loadNib = [[NSNib alloc] initWithNibNamed: @"load" bundle: nil];
	[loadNib retain];
	NSArray *arr2;
	[loadNib instantiateNibWithOwner: self topLevelObjects: &arr2];
		
	_prefView = [arr2 objectAtIndex: 1];
	[_prefView retain];
	return _prefView;
}

- (void) beep: (id) something {
}

- (void) fire {
	int enabled = [[[NSUserDefaults standardUserDefaults] objectForKey: @"loadEnabled"] intValue];
	if (!enabled) {
		[self setHidden: YES];
		[self setPriority: 1];
		return;
	}
	[self setHidden: NO];
	
	double loads[3];
	getloadavg(loads, 3);
	
	NSString *status = [[NSString alloc] initWithFormat: @"Load: %0.2f %0.2f %0.2f", loads[0], loads[1], loads[2]];	
	[self setShortTitle: status];
	[self setTitle: status];
	[status release];

	if (loads[0] < 0.1 && loads[1] < 0.1 && loads[2] < 0.1)
		[self setPriority: 6];
	else if (loads[0] < 1.0)
		[self setPriority: 14];
	else
		[self setPriority: 17];
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end