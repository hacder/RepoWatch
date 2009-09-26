#import "ButtonDelegate.h"
#import <dispatch/dispatch.h>

@implementation ButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super init];
	script = sc;
	[script retain];
	mainController = mc;
	statusItem = si;
	menu = m;
	title = s;
	[title retain];
	shortTitle = s;
	[shortTitle retain];
	priority = 0;
	[self addMenuItem];
	[self setupTimer];
	return self;
}

- (NSView *) preferences {
	return nil;
}

- (void) realTimer: (int)t {
	dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
	dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), 1ull * t * NSEC_PER_SEC, 1ull * NSEC_PER_SEC);
	dispatch_source_set_event_handler(timer, ^{
		[self fire];
	});
	dispatch_resume(timer);
}

- (void) setHidden: (BOOL) b {
	dispatch_async(dispatch_get_main_queue(), ^{
		[menuItem setHidden: b];
	});
}

- (void) setTitle: (NSString *)t {
	// This needs to be done on the main queue.
	dispatch_async(dispatch_get_main_queue(), ^{
		[menuItem setTitle: t];
		[title release];
		title = t;
		[title retain];
	});
}

/*
- (void) forceRearrage {
	dispatch_async(dispatch_get_main_queue(), ^{
		[mainController rearrange];
	});
}
*/

- (void) setShortTitle: (NSString *)t {
	[shortTitle release];
	shortTitle = t;
	[shortTitle retain];
	dispatch_async(dispatch_get_main_queue(), ^{
		[mainController maybeRefresh: self];
	});
}

- (NSString *) shortTitle {
	return shortTitle;
}

- (void) forceRefresh {
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[self fire];
	});
}

- (void) addMenuItem {
	dispatch_async(dispatch_get_main_queue(), ^{
		menuItem = [menu insertItemWithTitle: title action: @selector(beep:) keyEquivalent: @"" atIndex: [menu numberOfItems]];
		[menuItem retain];
		[menuItem setTarget: self];
		[menuItem setAction: @selector(beep:)];
	});
}

- (void) setupTimer {
	[self realTimer: 30];
}

- (void) beep: (id) something {
	if (script == nil) {
		// If we're not a script, and we haven't overridden this function, just "refresh" the
		// display.
		[self fire];
	} else {
		NSString *s = [self runScriptWithArgument: @"click"];
		NSMenu *tempMenu = [[NSMenu alloc] initWithTitle: @"Temp"];
		[tempMenu insertItemWithTitle: s action: nil keyEquivalent: @"" atIndex: 0];
		[statusItem popUpStatusItemMenu: tempMenu];
	}
}

- (void) fire {
	NSString *priString = [[self runScriptWithArgument: @"level"] autorelease];
	
	NSFont *stringFont;
	stringFont = [NSFont systemFontOfSize: 14.0];

	NSString *mainString = [[self runScriptWithArgument: @"update"] autorelease];
	
	[self setTitle: mainString];
	[self setShortTitle: mainString];
	[self setPriority: [priString intValue]];
}

- (void) setPriority: (int) p {
	if (priority == p)
		return;
	priority = p;
	[mainController rearrange];
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
	if (script != nil) {
		task = [[NSTask alloc] init];
		[task setLaunchPath: script];
		NSArray *arr = [NSArray arrayWithObject: arg];
		[task setArguments: arr];

		NSPipe *pipe = [NSPipe pipe];
		[task setStandardOutput: pipe];
		
		NSFileHandle *file = [pipe fileHandleForReading];
		
		[task launch];
		
		NSData *data = [file readDataToEndOfFile];
		NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		[task release];
		return string;
	}
	return @"Error";
}

@end