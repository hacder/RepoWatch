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
	[self setTitle: s];
	[self setShortTitle: s];
	[self setPriority: 0];
	[self addMenuItem];
	[self setupTimer];
	return self;
}

- (NSView *) preferences {
	return nil;
}

- (void) realTimer: (int)t {
	timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
	dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), 1ull * t * NSEC_PER_SEC, 1ull * NSEC_PER_SEC);
	dispatch_source_set_event_handler(timer, ^{
		struct timeval tv_start;
		struct timeval tv_end;
		
		gettimeofday(&tv_start, NULL);
		[self fire];
		gettimeofday(&tv_end, NULL);
		
		long msec = ((tv_end.tv_sec - tv_start.tv_sec) * 1000 + (tv_end.tv_usec - tv_start.tv_usec) / 1000.0) + 0.5;
		if (msec > 500)
			NSLog(@"%@->fire  took %ld msec", self, msec);
	});
	dispatch_resume(timer);
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

- (void) addMenuItem {
	menuItem = [menu insertItemWithTitle: title action: @selector(beep:) keyEquivalent: @"" atIndex: [menu numberOfItems]];
	[menuItem retain];
	[menuItem setTarget: self];
	[menuItem setAction: @selector(beep:)];
}

- (void) setupTimer {
	[self realTimer: 30];
}

- (void) beep: (id) something {
	if (script == nil) {
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