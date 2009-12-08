#import "PreferencesButtonDelegate.h"

@implementation PreferencesButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc plugins: (NSArray *)plugins {
	self = [self initWithTitle: s menu: m statusItem: si mainController: mc];
	_plugins = plugins;
	[self setTitle: @"Preferences"];
	return self;
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mc];
	return self;
}

- (void) beep: (id) something {
	[NSApp activateIgnoringOtherApps: YES];

	NSNib *nib = [[[NSNib alloc] initWithNibNamed: @"preferences" bundle: nil] autorelease];
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

- (BOOL) windowShouldClose: (id) win {
	window = nil;
	[[NSUserDefaultsController sharedUserDefaultsController] save: self];
	return YES;
}

@end