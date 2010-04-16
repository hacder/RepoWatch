#import "ButtonDelegate.h"
#import "MainController.h"
#import <dispatch/dispatch.h>
#import <sys/time.h>

@implementation ButtonDelegate

- (void) setShortTitle: (NSString *)t {
	if ([t isEqual: shortTitle])
		return;

	[t retain];
	[shortTitle release];
	shortTitle = t;
	[[NSNotificationCenter defaultCenter] postNotificationName: @"updateTitle" object: self];
}

- (NSString *) shortTitle {
	return shortTitle;
}

- (void) forceRefresh {
	[self fire: nil];
}

- (void) beep: (id) something {
}

- (void) fire: (NSTimer *)t {
}

@end