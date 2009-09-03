#import "ButtonDelegate.h"
#import <dispatch/dispatch.h>

@implementation ButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super init];
	script = sc;
	mainController = mc;
	statusItem = si;
	menu = m;
	title = s;
	shortTitle = s;
	priority = 0;
	[self addMenuItem];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[self setupTimer];
	});
	return self;
}

- (void) setHidden: (BOOL) b {
	dispatch_async(dispatch_get_main_queue(), ^{
		[menuItem setHidden: b];
	});
}

- (void) setTitle: (NSString *)t {
	[title release];
	title = t;
	[title retain];
	// This needs to be done on the main queue.
	dispatch_async(dispatch_get_main_queue(), ^{
		[menuItem setTitle: t];
		[mainController rearrange];
	});
}

- (void) forceRearrage {
	dispatch_async(dispatch_get_main_queue(), ^{
		[mainController rearrange];
	});
}

- (void) setShortTitle: (NSString *)t {
	[shortTitle release];
	shortTitle = t;
	[shortTitle retain];
}

- (NSString *) shortTitle {
	return shortTitle;
}

- (void) forceRefresh {
	[self fire: nil];
}

- (void) addMenuItem {
	menuItem = [menu insertItemWithTitle: title action: @selector(beep:) keyEquivalent: @"" atIndex: [menu numberOfItems]];
	[menuItem setTarget: self];
	[menuItem setAction: @selector(beep:)];
}

- (void) setupTimer {
	[NSTimer scheduledTimerWithTimeInterval: 30.0 target: self selector: @selector(fire:) userInfo: nil repeats: YES];
	[self fire: nil];
}

- (void) beep: (id) something {
	NSString *s = [self runScriptWithArgument: @"click"];
	NSMenu *tempMenu = [[NSMenu alloc] initWithTitle: @"Temp"];
	[tempMenu insertItemWithTitle: s action: nil keyEquivalent: @"" atIndex: 0];
	[statusItem popUpStatusItemMenu: tempMenu];
}

- (void) fire: (NSTimer *)t {
	priority = [[self runScriptWithArgument: @"level"] intValue];
	NSFont *stringFont;
	if (priority <= 10)
		stringFont = [NSFont systemFontOfSize: 9.0];
	else if (priority <= 20)
		stringFont = [NSFont systemFontOfSize: 14.0];
	else
		stringFont = [NSFont systemFontOfSize: 20.0];
	NSDictionary *stringAttributes = [NSDictionary dictionaryWithObject: stringFont forKey: NSFontAttributeName];
	NSString *mainString = [self runScriptWithArgument: @"update"];
	NSAttributedString *lowerString = [[NSAttributedString alloc] initWithString: mainString attributes: stringAttributes];
	title = mainString;
	[menuItem setAttributedTitle: lowerString];
	[mainController rearrange];
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
	if (script != nil) {
		task = [[NSTask alloc] init];
		[task setLaunchPath: script];
		[task setArguments: [NSArray arrayWithObject: arg]];

		NSPipe *pipe = [NSPipe pipe];
		[task setStandardOutput: pipe];
		
		NSFileHandle *file = [pipe fileHandleForReading];
		
		[task launch];
		
		NSData *data = [file readDataToEndOfFile];
		NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		return string;
	}
	return @"Error";
}

@end