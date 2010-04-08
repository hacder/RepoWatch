#import "MainMenu.h"
#import "RepoButtonDelegate.h"
#import "BubbleFactory.h"

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
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(repositoryTitleUpdate:) name: @"updateTitle" object: nil];
	return self;
}

- (NSMenuItem *) menuItemForRepository: (RepoButtonDelegate *)rbd {
	int i;
	for (i = 0; i < [self numberOfItems]; i++) {
		RepoButtonDelegate *rbd2 = [[self itemAtIndex: i] target];
		if (rbd2 == rbd)
			return [self itemAtIndex: i];
	}
	return nil;
}

- (void) repositoryTitleUpdate: (NSNotification *)note {
	NSMenuItem *mi = [self menuItemForRepository: [note object]];
	[mi setTitle: [[note object] shortTitle]];
}

- (void) insertRepository: (RepoButtonDelegate *)rbd {
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle: [rbd shortTitle] action: nil keyEquivalent: @""];
	// NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle: [NSString stringWithFormat: @"%@ (%d)", [rbd shortTitle], [rbd getStateValue]] action: nil keyEquivalent: @""];

	int size = 10;
	if ([rbd getStateValue] == 40) {
		[menuItem setOffStateImage: [BubbleFactory getBlueOfSize: size]];
	} else if ([rbd getStateValue] == 30) {
		[menuItem setOffStateImage: [BubbleFactory getRedOfSize: size]];
	} else if ([rbd getStateValue] == 20) {			
		[menuItem setOffStateImage: [BubbleFactory getYellowOfSize: size]];
	} else if ([rbd getStateValue] == 10) {
		[menuItem setOffStateImage: [BubbleFactory getGreenOfSize: size]];
	}	
	
	[menuItem setTarget: rbd];
	
	int i;
	for (i = 0; i < [self numberOfItems]; i++) {
		// TODO: There will be other items in here. We can't actually guarantee that this type conversion
		//       will work.
		RepoButtonDelegate *rbd2 = [[self itemAtIndex: i] target];
		if ([rbd2 getStateValue] > [rbd getStateValue])
			continue;
		if ([rbd2 getStateValue] == [rbd getStateValue]) {
			NSString *title1 = [rbd shortTitle];
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
	[self addItem: menuItem];
}

- (void) updateTitle {
	if ([self numberOfItems]) {
		RepoButtonDelegate *rbd = [[self itemAtIndex: 0] target];
		if ([rbd getStateValue] == 10) {
			[statusItem setTitle: @""];
		} else {
			[statusItem setTitle: [rbd shortTitle]];			
		}
		if ([rbd getStateValue] == 40) {
			[statusItem setImage: [BubbleFactory getBlueOfSize: 16]];
		} else if ([rbd getStateValue] == 30) {
			[statusItem setImage: [BubbleFactory getRedOfSize: 16]];
		} else if ([rbd getStateValue] == 20) {			
			[statusItem setImage: [BubbleFactory getYellowOfSize: 16]];
		} else if ([rbd getStateValue] == 10) {
			[statusItem setImage: [BubbleFactory getGreenOfSize: 16]];
		}	
	} else {
		[statusItem setTitle: @"No Items"];
	}
}

- (void) rearrangeRepository: (NSNotification *)notification {
	RepoButtonDelegate *rbd = [notification object];
	int i;
	for (i = 0; i < [self numberOfItems]; i++) {
		if ([[self itemAtIndex: i] target] == rbd) {
			[self removeItemAtIndex: i];
			break;
		}
	}
	[self insertRepository: rbd];
	[self updateTitle];
}

- (void) newRepository: (NSNotification *)notification {
	RepoButtonDelegate *rbd = [notification object];
	[self insertRepository: rbd];
	[self updateTitle];
}

@end