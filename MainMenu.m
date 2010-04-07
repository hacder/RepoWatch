#import "MainMenu.h"
#import "RepoButtonDelegate.h"

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
	return self;
}

- (void) insertRepository: (RepoButtonDelegate *)rbd {
	NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle: [rbd shortTitle] action: nil keyEquivalent: @""];
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

- (void) rearrangeRepository: (NSNotification *)notification {
	RepoButtonDelegate *rbd = [notification object];
	NSLog(@"Rearranging %@: %d", [[rbd repository] lastPathComponent], [rbd getStateValue]);
	int i;
	for (i = 0; i < [self numberOfItems]; i++) {
		if ([[self itemAtIndex: i] target] == rbd) {
			NSLog(@"Found the item to remove");
			[self removeItemAtIndex: i];
			break;
		}
	}
	NSLog(@"Inserting");
	[self insertRepository: rbd];
}

- (void) newRepository: (NSNotification *)notification {
	RepoButtonDelegate *rbd = [notification object];
	[self insertRepository: rbd];
	if ([self numberOfItems]) {
		[statusItem setTitle: [[[self itemAtIndex: 0] target] shortTitle]];
	} else {
		[statusItem setTitle: @"No Items"];
	}
}

@end