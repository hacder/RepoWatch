#import "ButtonDelegate.h"
#import "MainController.h"
#import <dispatch/dispatch.h>
#import <sys/time.h>

@implementation ButtonDelegate

- initWithTitle: (NSString *)s mainController: (MainController *)mcc {
	self = [super init];
	mc = mcc;
	[mc retain];
	[self setTitle: s];
	[self setShortTitle: s];
	return self;
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
	[mc maybeRefresh: self];
}

- (NSString *) shortTitle {
	return shortTitle;
}

- (void) forceRefresh {
	[self fire: nil];
}

- (NSMenuItem *)getMenuItem {
	return menuItem;
}

- (void) beep: (id) something {
}

- (void) fire: (NSTimer *)t {
}

@end