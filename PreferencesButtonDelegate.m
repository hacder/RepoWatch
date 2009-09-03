#import "PreferencesButtonDelegate.h"

@implementation PreferencesButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	[super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	defaults = [NSUserDefaults standardUserDefaults];
	twitterUsername = [defaults objectForKey: @"twitterUsername"];
	twitterPassword = [defaults objectForKey: @"twitterPassword"];
	bitlyEnabled = [defaults boolForKey: @"bitlyEnabled"];
}

- (void) setupTimer {
	[NSTimer scheduledTimerWithTimeInterval: 120.0 target: self selector: @selector(fire:) userInfo: nil repeats: YES];
	[self fire: nil];
}

- (void) beep: (id) something {
	dispatch_async(dispatch_get_main_queue(), ^{
		[NSApp activateIgnoringOtherApps: YES];
		if (window != nil) {
			[window makeKeyAndOrderFront: nil];
			return;
		}
		
		NSNib *nib = [[NSNib alloc] initWithNibNamed: @"preferences" bundle: nil];
		NSArray *arr;
		[nib instantiateNibWithOwner: nil topLevelObjects: &arr];
		
		int i = 0;
		for (; i < [arr count]; i++) {
			if ([[arr objectAtIndex: i] isMemberOfClass: [NSWindow class]]) {
				window = [arr objectAtIndex: i];
				break;
			}
		}
		if (window == nil)
			return;
		
		[window setTitle: @"Preferences"];
		[window display];
		
		NSArray *subviews = [[window contentView] subviews];
		for (i = 0; i < [subviews count]; i++) {
			if ([[subviews objectAtIndex: i] isMemberOfClass: [NSSecureTextField class]]) {
				_twitterPassword = [subviews objectAtIndex: i];
				if ([defaults stringForKey: @"twitterPassword"] != nil)
					[_twitterPassword setStringValue: [defaults stringForKey: @"twitterPassword"]];
			} else if ([[subviews objectAtIndex: i] isMemberOfClass: [NSButton class]]) {
				_bitlyEnabled = [subviews objectAtIndex: i];
				[_bitlyEnabled setState: [defaults boolForKey: @"bitlyEnabled"]];
			} else if ([[subviews objectAtIndex: i] isMemberOfClass: [NSTextField class]]) {
				NSTextField *tf = [subviews objectAtIndex: i];
				if ([tf isEditable]) {
					_twitterUsername = [subviews objectAtIndex: i];
					if ([defaults stringForKey: @"twitterUsername"] != nil)
						[_twitterUsername setStringValue: [defaults stringForKey: @"twitterUsername"]];
				}
			}
		}
		
		[window makeKeyAndOrderFront: nil];
		[window makeKeyWindow];
		[window center];
			
		[window setDelegate: self];
	});
}

- (void) fire: (NSTimer *)t {
	priority = -100;
	[self setTitle: @"Preferences"];
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

- (BOOL) windowShouldClose: (id) win {
	[defaults setBool: [_bitlyEnabled state] == NSOnState forKey: @"bitlyEnabled"];
	bitlyEnabled = [_bitlyEnabled state] == NSOnState;
	[defaults setObject: [_twitterUsername stringValue] forKey: @"twitterUsername"];
	twitterUsername = [_twitterUsername stringValue];
	[defaults setObject: [_twitterPassword stringValue] forKey: @"twitterPassword"];
	twitterPassword = [_twitterPassword stringValue];
	[defaults synchronize];
	[mainController reset];
	return YES;
}

@end