#import "ButtonDelegate.h"
#import <dispatch/dispatch.h>
#import <sys/time.h>

@implementation ButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super init];
	mainController = mc;
	statusItem = si;
	menu = m;
	[self setTitle: s];
	[self setShortTitle: s];
	[self addMenuItem];
	return self;
}

- (NSView *) preferences {
	return nil;
}

- (void) setHidden: (BOOL) b {
	[menuItem setHidden: b];
	[mainController maybeRefresh: self];
}

- (void) setTitle: (NSString *)t {
	[t retain];
	[menuItem setTitle: t];
	[title release];
	title = t;
}

- (void) setShortTitle: (NSString *)t {
	if ([t isEqual: shortTitle])
		return;
	[t retain];
	[shortTitle release];
	shortTitle = t;
	[mainController maybeRefresh: self];
}

- (NSString *) shortTitle {
	return shortTitle;
}

- (void) forceRefresh {
	[self fire];
}

- (NSMenuItem *)getMenuItem {
	return menuItem;
}

- (void) addMenuItem {
	menuItem = [menu insertItemWithTitle: title action: @selector(beep:) keyEquivalent: @"" atIndex: [menu numberOfItems]];
	[menuItem retain];
	[menuItem setTarget: self];
	[menuItem setAction: @selector(beep:)];
}

- (void) beep: (id) something {
}

- (void) fire {
}

@end