#import "MainMenu.h"
#import "RepoButtonDelegate.h"
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
	return self;
}

- (RepoMenuItem *) menuItemForRepository: (RepoButtonDelegate *)rbd {
	int i;
	for (i = 0; i < [self numberOfItems]; i++) {
		RepoButtonDelegate *rbd2 = [[self itemAtIndex: i] target];
		if (rbd2 == rbd)
			return (RepoMenuItem *)[self itemAtIndex: i];
	}
	return nil;
}

- (void) insertRepository: (RepoButtonDelegate *)rbd {
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self insertRepository: rbd];
		});
		return;
	}
	
	RepoMenuItem *menuItem = [rbd getMenuItem];
	if (!menuItem)
		menuItem = [[RepoMenuItem alloc] initWithRepository: rbd];

	int size = 10;
	int stateValue = [rbd getStateValue];

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
	
	if (stateValue >= 40) {
		[menuItem setOffStateImage: [BubbleFactory getBlueOfSize: size]];
	} else if (stateValue >= 30) {
		[menuItem setOffStateImage: [BubbleFactory getRedOfSize: size]];
	} else if (stateValue >= 20) {			
		[menuItem setOffStateImage: [BubbleFactory getYellowOfSize: size]];
	} else if (stateValue >= 10) {
		[menuItem setOffStateImage: [BubbleFactory getGreenOfSize: size]];
	}	
	
	[menuItem setTarget: rbd];
	
	int i;
	int state1 = [rbd getStateValue];
	NSString *title1 = [rbd shortTitle];

	for (i = 0; i < [self numberOfItems]; i++) {
		// TODO: There will be other items in here. We can't actually guarantee that this type conversion
		//       will work.
		RepoButtonDelegate *rbd2 = [[self itemAtIndex: i] target];
		int stateValue = [rbd2 getStateValue];
		if (stateValue > state1)
			continue;
		if (stateValue == state1) {
			NSString *title2 = [rbd2 shortTitle];
			NSComparisonResult res = [title1 caseInsensitiveCompare: title2];

			if (res == NSOrderedAscending) {
				[self insertItem: menuItem atIndex: i];
				return;
			} else {
				continue;
			}
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
		RepoButtonDelegate *rbd = [[self itemAtIndex: 0] target];
		if ([rbd getStateValue] < 20) {
			[statusItem setTitle: @""];
		} else {
			[statusItem setTitle: [rbd shortTitle]];			
		}

		int size = 16;
		if ([rbd getStateValue] >= 40) {
			[statusItem setImage: [BubbleFactory getBlueOfSize: size]];
		} else if ([rbd getStateValue] >= 30) {
			[statusItem setImage: [BubbleFactory getRedOfSize: size]];
		} else if ([rbd getStateValue] >= 20) {			
			[statusItem setImage: [BubbleFactory getYellowOfSize: size]];
		} else if ([rbd getStateValue] >= 10) {
			[statusItem setImage: [BubbleFactory getGreenOfSize: size]];
		}	
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
	
	RepoButtonDelegate *rbd = [notification object];
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
	RepoButtonDelegate *rbd = [notification object];
	NSLog(@"newRepository: %@", rbd);
	[self insertRepository: rbd];
	[self updateTitle];
}

@end