#import "MainController.h"
#import "ButtonDelegate.h"
#import "LoadButtonDelegate.h"
#import "TwitterTrendingButtonDelegate.h"
#import "PreferencesButtonDelegate.h"
#import "SeparatorButtonDelegate.h"
#import "BitlyStatsButtonDelegate.h"
#import "QuitButtonDelegate.h"
#import "TimeMachineAlertButtonDelegate.h"
#import "TwitFollowerButtonDelegate.h"
#import <dirent.h>

@implementation MainController

- init {
	self = [super init];
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	statusItem = [bar statusItemWithLength: NSVariableStatusItemLength];
	[statusItem retain];
	
	[statusItem setTitle: NSLocalizedString(@"Initializing...", @"")];
	[statusItem setHighlightMode: YES];
	theMenu = [[[NSMenu alloc] initWithTitle: @"Testing"] retain];
	
	[statusItem setMenu: theMenu];
	
	NSArray *defaultKeys = [NSArray arrayWithObjects:
			@"twitterUsername",
			@"twitterPassword",
			@"bitlyEnabled",
			@"shortTwitterTrendCount",
			@"bitlyTwitterHistory",
			@"bitlyDelay",
			@"loadDelay",
			@"trendDelay", nil];
	NSArray *defaultValues = [NSArray arrayWithObjects:
			@"",
			@"",
			@"YES",
			@"3",
			@"20",
			@"300",
			@"10",
			@"120", nil];
	NSDictionary *dict = [NSDictionary dictionaryWithObjects: defaultValues forKeys: defaultKeys];
	[[NSUserDefaults standardUserDefaults] registerDefaults: dict];	
	plugins = [[NSMutableArray alloc] initWithCapacity: 10];
	return self;
}

- initWithDirectory: (NSString *)dir {
	[self init];
	[self addDir: dir];
	[plugins addObject: [[LoadButtonDelegate alloc] initWithTitle: @"System Load" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[PreferencesButtonDelegate alloc] initWithTitle: @"Preferences" menu: theMenu script: nil statusItem: statusItem mainController: self plugins: plugins]];
	[plugins addObject: [[TwitterTrendingButtonDelegate alloc] initWithTitle: @"Twitter Trending" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[SeparatorButtonDelegate alloc] initWithTitle: @"Separator" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[QuitButtonDelegate alloc] initWithTitle: @"Quit" menu: theMenu script: nil statusItem: statusItem mainController: self]];
//	[plugins addObject: [[BitlyStatsButtonDelegate alloc] initWithTitle: @"Bitly" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[TimeMachineAlertButtonDelegate alloc] initWithTitle: @"Time Machine" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[TwitFollowerButtonDelegate alloc] initWithTitle: @"Twitter Follower" menu: theMenu script: nil statusItem: statusItem mainController: self]];
}

- addDir: (NSString *)dir {
	DIR *dire = opendir([dir cStringUsingEncoding: NSUTF8StringEncoding]);
	if (dire == NULL)
		return;
	struct dirent *dent;
	while ((dent = readdir(dire)) != NULL) {
		if (dent->d_name[0] == '.')
			continue;
		NSString *total = [[dir stringByAppendingString: @"/"] stringByAppendingString: [[NSString alloc] initWithCString: dent->d_name encoding: NSUTF8StringEncoding]];
		ButtonDelegate *bd = [[ButtonDelegate alloc] initWithTitle: total menu: theMenu script: total statusItem: statusItem mainController: self];
	}
	closedir(dire);
}

NSInteger sortMenuItems(id item1, id item2, void *context) {
	ButtonDelegate *bd1 = [item1 target];
	ButtonDelegate *bd2 = [item2 target];
	if (bd1 == nil || bd2 == nil)
		return NSOrderedSame;
	if (bd1->priority < bd2->priority)
		return NSOrderedDescending;
	if (bd1->priority > bd2->priority)
		return NSOrderedAscending;
	return NSOrderedSame;
}

- (void) reset {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSArray *arr = [theMenu itemArray];
		int i;
		for (i = 0; i < [arr count]; i++) {
			ButtonDelegate *bd = [[arr objectAtIndex: i] target];
			[bd forceRefresh];
		}
	});
}

- (void) testpopup {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@"Pre");
		SEL click = [statusItem action];
		
		NSLog(@"Click is %@", click);
		[statusItem performSelector: click];
		
//		[statusItem popUpStatusItemMenu: theMenu];
		NSLog(@"Post");
	});
}

- (void) rearrange {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@"Rearranging");
		NSArray *arr = [[theMenu itemArray] sortedArrayUsingFunction: sortMenuItems context: NULL];
		int i;
		for (i = 0; i < [arr count]; i++) {
			ButtonDelegate *bd = [[arr objectAtIndex: i] target];
			[theMenu removeItem: [arr objectAtIndex: i]];
			[theMenu insertItem: [arr objectAtIndex: i] atIndex: i];
		}
		ButtonDelegate *bd2 = [[arr objectAtIndex: 0] target];
		NSString *sh = [bd2 shortTitle];
		[statusItem setTitle: sh];
	});
}

@end