#import "MainMenu.h"
#import "RepoInstance.h"
#import "BubbleFactory.h"
#import "RepoMenuItem.h"
#import "RepoList.h"

@implementation MainMenu

- (id) init {
	self = [super initWithTitle: @"MainMenu"];
	[self setAutoenablesItems: NO];
	
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	statusItem = [bar statusItemWithLength: NSVariableStatusItemLength];
	[statusItem retain];
	[statusItem setTitle: @"Initializing..."];
	[statusItem setHighlightMode: YES];
	[statusItem setMenu: self];	
	[statusItem setMenu: self];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(newRepository:) name: @"repoFound" object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(rearrangeRepository:) name: @"updateTitle" object: nil];
	
	green = [BubbleFactory getGreenOfSize: 10];
	[green retain];
	bigGreen = [BubbleFactory getGreenOfSize: 16];
	[bigGreen retain];
	red = [BubbleFactory getRedOfSize: 10];
	[red retain];
	bigRed = [BubbleFactory getRedOfSize: 16];
	[bigRed retain];
	yellow = [BubbleFactory getYellowOfSize: 10];
	[yellow retain];
	
	timer = [NSTimer scheduledTimerWithTimeInterval: 10.0 target: self selector: @selector(timer:) userInfo: nil repeats: NO];

	return self;
}

- (void) timer: (NSTimer *)t {
	NSArray *tmp = [[RepoList sharedInstance] allRepositories];
	int i;
	for (i = 0; i < [tmp count]; i++) {
		[[tmp objectAtIndex: i] tick];
	}
	timer = [NSTimer scheduledTimerWithTimeInterval: 10.0 target: self selector: @selector(timer:) userInfo: nil repeats: NO];
	[self updateMenu];
}

- (RepoMenuItem *) menuItemForRepository: (RepoInstance *)rbd {
	int i;
	for (i = 0; i < [self numberOfItems]; i++) {
		RepoInstance *rbd2 = [[self itemAtIndex: i] target];
		if (rbd2 == rbd)
			return (RepoMenuItem *)[self itemAtIndex: i];
	}
	return nil;
}

NSInteger sortRepositories(id num1, id num2, void *context) {
	BOOL oneLocal = [[num1 repository] hasLocal];
	BOOL twoLocal = [[num2 repository] hasLocal];
	
	if (oneLocal && !twoLocal)
		return NSOrderedAscending;
	if (twoLocal && !oneLocal)
		return NSOrderedDescending;


	BOOL oneRecent = [[num1 repository] logFromToday];
	BOOL twoRecent = [[num2 repository] logFromToday];

	if (oneRecent && !twoRecent)
		return NSOrderedAscending;
	if (twoRecent && !oneRecent)
		return NSOrderedDescending;
	
	return [[[num1 repository] shortTitle] caseInsensitiveCompare: [[num2 repository] shortTitle]];
}

- (NSArray *)sortedArray {
	NSArray *tmp = [self itemArray];
	return [tmp sortedArrayUsingFunction: sortRepositories context: nil];
}

- (void) insertRepository: (RepoInstance *)rbd {
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self insertRepository: rbd];
		});
		return;
	}
	
	RepoMenuItem *menuItem = [rbd menuItem];
	if (!menuItem) {
		menuItem = [[RepoMenuItem alloc] initWithRepository: rbd];
		if ([rbd hasLocal]) {
			[menuItem setOffStateImage: red];
		} else if ([rbd hasRemote]) {
			[menuItem setOffStateImage: yellow];
		} else {
			[menuItem setOffStateImage: green];
		}

	}
	if (!menuItem)
		return;
	
	if (![rbd logFromToday]) {
		NSString *menuItemTitle = [rbd shortTitle];
		NSAttributedString *menuItemAttributed = 
			[[NSAttributedString alloc]
				initWithString: menuItemTitle
				attributes: [NSDictionary dictionaryWithObjectsAndKeys:
					[NSColor grayColor],
					NSForegroundColorAttributeName,
					[NSFont systemFontOfSize: 12],
					NSFontAttributeName,
					nil]
			];
		[menuItem setAttributedTitle: menuItemAttributed];
	} else {
		[menuItem setTitle: [rbd shortTitle]];
	}
	
	[self insertItem: menuItem atIndex: [self numberOfItems]];
	[self updateMenu];
}

- (void) updateMenu {
	NSArray *dest = [self sortedArray];
	[self removeAllItems];
	if ([dest count] == 0)
		return;
		
	int i;
	for (i = 0; i < [dest count]; i++) {
		[self addItem: [dest objectAtIndex: i]];
	}
	
	RepoInstance *ri = [[dest objectAtIndex: 0] repository];
	if ([ri hasLocal]) {
		[statusItem setImage: bigRed];
		[statusItem setTitle: [ri shortTitle]];
	} else {
		[statusItem setImage: bigGreen];
		[statusItem setTitle: @""];
	}
}

// TODO: This is the source of a massive inefficiency.
- (void) rearrangeRepository: (NSNotification *)notification {
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self rearrangeRepository: notification];
		});
		return;
	}
	
	RepoInstance *rbd = [notification object];
	int i;
	BOOL foundIt = NO;
	for (i = 0; i < [self numberOfItems]; i++) {
		if ([[self itemAtIndex: i] target] == rbd) {
			[self removeItemAtIndex: i];
			foundIt = YES;
			break;
		}
	}
	if (!foundIt)
		NSLog(@"Uh oh, didn't find %@", rbd);
	[self insertRepository: rbd];
}

- (void) newRepository: (NSNotification *)notification {
	RepoInstance *rbd = [notification object];
	[self insertRepository: rbd];
}

@end