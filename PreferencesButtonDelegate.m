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
	return self;
}

- (void) setupTimer {
	[self realTimer: 120];
}

- (void) beep: (id) something {
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
	window = nil;
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[[NSUserDefaultsController sharedUserDefaultsController] save: self];
		dispatch_async(dispatch_get_main_queue(), ^{
			[mainController reset];
		});
	});
	return YES;
}

@end