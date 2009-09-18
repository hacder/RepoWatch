#import "PreferencesButtonDelegate.h"

@implementation PreferencesButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc plugins: (NSArray *)plugins {
	self = [self initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	_plugins = plugins;
	[self setPriority: -100];
	return self;
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	defaults = [NSUserDefaults standardUserDefaults];
	twitterUsername = [defaults objectForKey: @"twitterUsername"];
	twitterPassword = [defaults objectForKey: @"twitterPassword"];
	return self;
}

- (void) setupTimer {
	[self realTimer: 120];
}

- (void) beep: (id) something {
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		NSLog(@"Delaying Preferences'beep' until later...");
		dispatch_async(dispatch_get_main_queue(), ^{
			NSLog(@"Should be running beep now");
			[self beep: something];
		});
		return;
	}
	[NSApp activateIgnoringOtherApps: YES];

	NSNib *nib = [[NSNib alloc] initWithNibNamed: @"preferences" bundle: nil];
	NSArray *arr;
	[nib instantiateNibWithOwner: nil topLevelObjects: &arr];
	
	int i = 0;
	for (; i < [arr count]; i++) {
		if ([[arr objectAtIndex: i] isMemberOfClass: [NSWindow class]]) {
			window = [arr objectAtIndex: i];
			[window retain];
		}
	}
	if (window == nil)
		return;
	
	[window center];
	[window display];
	
	NSArray *subviews = [[window contentView] subviews];
	
	// Something is horribly wrong. Our main preferences window nib should ONLY have the tab view in it.
	// Someone's been editing things, and I can't be arsed to figure that out.
	if ([subviews count] > 1) {
		NSLog(@"Hit questionable path");
		return;
	}
	
	NSTabView *tv = [subviews objectAtIndex: 0];
	for (i = 0; i < [_plugins count]; i++) {
		ButtonDelegate *bd = [_plugins objectAtIndex: i];
		NSView *v = [bd preferences];
		if (v == nil)
			continue;
		[v retain];
		NSTabViewItem *tvi = [[NSTabViewItem alloc] initWithIdentifier: bd];
		[tvi setView: v];
		[tvi setLabel: [bd shortTitle]];
		[tv addTabViewItem: tvi];
	}
	
	[window makeKeyAndOrderFront: nil];
	[window makeKeyWindow];
		
	[window setDelegate: self];
}

- (void) fire {
	[self setTitle: @"Preferences"];
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

- (BOOL) windowShouldClose: (id) win {
	NSLog(@"Window should close from: %s", dispatch_queue_get_label(dispatch_get_main_queue()));
	[defaults setObject: [_twitterUsername stringValue] forKey: @"twitterUsername"];
	twitterUsername = [_twitterUsername stringValue];
	[defaults setObject: [_twitterPassword stringValue] forKey: @"twitterPassword"];
	twitterPassword = [_twitterPassword stringValue];
	[defaults synchronize];
	[mainController reset];
	window = nil;
	return YES;
}

@end