#import "MainMenu.h"
#import "RepoInstance.h"
#import "BubbleFactory.h"
#import "RepoMenuItem.h"

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
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(rearrangeRepository:) name: @"repoStateChange" object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(rearrangeRepository:) name: @"updateTitle" object: nil];
//	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(scannerDone:) name: @"scannerDone" object: nil];
	
	green = [BubbleFactory getGreenOfSize: 10];
	[green retain];
	bigGreen = [BubbleFactory getGreenOfSize: 16];
	[bigGreen retain];

	return self;
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
		[menuItem setOffStateImage: green];
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
	NSArray *dest = [self sortedArray];
	[self removeAllItems];
	int i;
	for (i = 0; i < [dest count]; i++) {
		[self addItem: [dest objectAtIndex: i]];
	}
}

- (void) updateTitle {
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self updateTitle];
		});
		return;
	}
	
	if ([self numberOfItems]) {
		[statusItem setTitle: @""];
		[statusItem setImage: bigGreen];
	} else {
		[statusItem setTitle: @"No Items"];
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
	[self updateTitle];
}

- (void) newRepository: (NSNotification *)notification {
	RepoInstance *rbd = [notification object];
	[self insertRepository: rbd];
	[self updateTitle];
}

@end