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
			@"trendNumber",
			@"bitlyEnabled",
			@"bitlyTimeout",
			@"bitlyTwitterHistory",
			@"trendMundaneFilter",
			@"timeMachineEnabled",
			@"timeMachineOverdueTime",
			@"defollowEnabled",
			@"bitlyDelay",
			@"loadDelay",
			@"trendDelay",
			@"followerDelay",
			nil];
	NSArray *defaultValues = [NSArray arrayWithObjects:
			@"3",
			@"1",
			@"2",
			@"50",
			@"1",
			@"1",
			@"5",
			@"1",
			@"60",
			@"10",
			@"600",
			@"600",
			nil];
	NSDictionary *dict = [NSDictionary dictionaryWithObjects: defaultValues forKeys: defaultKeys];
	[[NSUserDefaults standardUserDefaults] registerDefaults: dict];	
	plugins = [[NSMutableArray alloc] initWithCapacity: 10];
	return self;
}

- initWithDirectory: (NSString *)dir {
	[self init];
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"C42XXY"] == 1)
		[self addDir: dir];
	[plugins addObject: [[LoadButtonDelegate alloc] initWithTitle: @"System Load" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[PreferencesButtonDelegate alloc] initWithTitle: @"Preferences" menu: theMenu script: nil statusItem: statusItem mainController: self plugins: plugins]];
	[plugins addObject: [[TwitterTrendingButtonDelegate alloc] initWithTitle: @"Twitter Trending" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[SeparatorButtonDelegate alloc] initWithTitle: @"Separator" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[QuitButtonDelegate alloc] initWithTitle: @"Quit" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[BitlyStatsButtonDelegate alloc] initWithTitle: @"Bitly" menu: theMenu script: nil statusItem: statusItem mainController: self]];
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
		[self rearrange];
	});
}

- (void) maybeRefresh: (ButtonDelegate *)bd {
	NSArray *arr = [theMenu itemArray];
	if ([arr count] == 0)
		return;
	ButtonDelegate *bd2 = [[arr objectAtIndex: 0] target];
	if (bd2 == bd)
		[self rearrange];
}

- (void) rearrange {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSArray *arr = [[theMenu itemArray] sortedArrayUsingFunction: sortMenuItems context: NULL];
		int i;
		for (i = 0; i < [arr count]; i++) {
			ButtonDelegate *bd = [[arr objectAtIndex: i] target];
			[theMenu removeItem: [arr objectAtIndex: i]];
			[theMenu insertItem: [arr objectAtIndex: i] atIndex: i];
		}
		for (i = 0; i < [arr count]; i++) {
			if ([[arr objectAtIndex: i] isHidden] == NO) {
				ButtonDelegate *bd2 = [[arr objectAtIndex: i] target];
				NSString *sh = [bd2 shortTitle];
				[statusItem setTitle: sh];
				break;
			}
		}
	});
}

@end