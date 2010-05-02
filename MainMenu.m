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
	}

	int size = 10;

	if ([rbd logFromToday]) {
		size = 12;
	} else {
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor grayColor],
			NSForegroundColorAttributeName,
			[NSFont labelFontOfSize: 12],
			NSFontAttributeName,
			nil];
		NSMutableAttributedString *newTitle = [[NSMutableAttributedString alloc] initWithString: [rbd shortTitle] attributes: attributes];
		[menuItem setAttributedTitle: newTitle];
	}
	
	[menuItem setOffStateImage: [BubbleFactory getGreenOfSize: size]];
	[menuItem setTarget: rbd];
	
	int i;
	NSString *title1 = [rbd shortTitle];

	for (i = 0; i < [self numberOfItems]; i++) {
		// TODO: There will be other items in here. We can't actually guarantee that this type conversion
		//       will work.
		RepoInstance *rbd2 = [[self itemAtIndex: i] target];
		NSString *title2 = [rbd2 shortTitle];
		NSComparisonResult res = [title1 caseInsensitiveCompare: title2];

		if (res == NSOrderedAscending) {
			[self insertItem: menuItem atIndex: i];
			return;
		} else {
			continue;
		}
		[self insertItem: menuItem atIndex: i];
		return;
	}

	// It goes at the end!
	[self addItem: menuItem];
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
		int size = 16;
		[statusItem setImage: [BubbleFactory getGreenOfSize: size]];
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