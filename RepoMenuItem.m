#import "RepoMenuItem.h"
#import "RepoInstance.h"
#import "MainController.h"

@implementation RepoMenuItem

- (void) doUpdateMenu: (NSNotification *)notif {
	// Do this before we do work, so that it serves as a stupid little race preventor.
	[lastUpdate release];
	lastUpdate = [NSDate date];
	[lastUpdate retain];
	
	NSArray *logs = [repo logs];
	int i;
	
	NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity: [logs count]];
	NSMutableArray *dateAttrStrings = [NSMutableArray arrayWithCapacity: [logs count]];
	NSMutableArray *logStrings = [NSMutableArray arrayWithCapacity: [logs count]];
	NSMutableArray *hashs = [NSMutableArray arrayWithCapacity: [logs count]];
	
	for (i = 0; i < [logs count]; i++) {
		NSString *currentPiece = [logs objectAtIndex: i];
		NSArray *pieces = [currentPiece componentsSeparatedByString: @" "];
		NSString *timestamp = [pieces objectAtIndex: 1];
		NSString *hash = [pieces objectAtIndex: 2];
	
		NSRange theRange;
		theRange.location = 0;
		theRange.length = [pieces count];
	
		NSArray *logMessage = [pieces subarrayWithRange: theRange];
		NSString *logString = [NSString stringWithFormat: @" %@", [logMessage componentsJoinedByString: @" "]];
		NSString *dateString = [dateFormatter stringFromDate: [NSDate dateWithTimeIntervalSince1970: [timestamp intValue]]];
		NSMutableAttributedString *dateAttrString = [[NSMutableAttributedString alloc] initWithString: dateString attributes: dateAttributes];
		NSAttributedString *logAttributed = [[NSAttributedString alloc] initWithString: logString attributes: logAttributes];
		[logAttributed autorelease];
		[dateAttrString appendAttributedString: logAttributed];
		[dateAttrString autorelease];
	
		NSString *title = [NSString stringWithFormat: @"%@ %@", dateString, logString];
		[menuItems addObject: title];
		[dateAttrStrings addObject: dateAttrString];
		[logStrings addObject: logString];
		[hashs addObject: hash];
	}
	dispatch_async(dispatch_get_main_queue(), ^{
		int i;
		NSMenuItem *mi;
		[sub removeAllItems];
		for (i = 0; i < [menuItems count]; i++) {
			mi = [sub addItemWithTitle: [menuItems objectAtIndex: i] action: nil keyEquivalent: @""];
			[mi setAttributedTitle: [dateAttrStrings objectAtIndex: i]];
			[mi setToolTip: [logStrings objectAtIndex: i]];
			[mi setRepresentedObject: [hashs objectAtIndex: i]];
		}
	
		if ([repo hasUntracked] || [repo hasLocal] || [repo hasUpstream])
			[sub addItem: [NSMenuItem separatorItem]];
	
		if ([repo hasLocal]) {
			mi = [sub addItemWithTitle: @"Commit Local Changes" action: @selector(commitFromMenu:) keyEquivalent: @""];
			[mi setRepresentedObject: repo];
			[mi setTarget: [MainController sharedInstance]];
		}
		[lock unlock];
	});	
}

- (void) updateMenu: (NSNotification *)notif {
	// We must lock on a consistent thread. The only way to do that is to lock on
	// the main thread. Sigh.
	
	// NOTE: This lock IS unlocked. Though you can't see it here. We have to call
	// into the main queue in order to actually do the visual updates. It is
	// unlocked there. Unlocking here would unlock potentially early.
	dispatch_async(dispatch_get_main_queue(), ^{
		if (![lock tryLock])
			return;
		
		dispatch_async(dispatch_get_global_queue(0, 0), ^{
			[self doUpdateMenu: notif];
		});
	});
}

- (id) initWithRepository: (RepoInstance *)rep {
	self = [super initWithTitle: [rep shortTitle] action: nil keyEquivalent: @""];
	repo = rep;
	[repo retain];
	[self setToolTip: [repo repository]];
	lock = [[NSLock alloc] init];
	[rep setMenuItem: self];
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle: NSDateFormatterShortStyle];
	[dateFormatter setDateStyle: NSDateFormatterMediumStyle];
	[dateFormatter setDoesRelativeDateFormatting: YES];
	
	dateAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor grayColor],
		NSForegroundColorAttributeName,
		[NSFont labelFontOfSize: 10],
		NSFontAttributeName,
		nil];
	[dateAttributes retain];
	logAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor blackColor],
		NSForegroundColorAttributeName,
		[NSFont systemFontOfSize: 14],
		NSFontAttributeName,
		nil];
	[logAttributes retain];
	
	// Update the menu no matter what the notification is. We may have to filter some out later on to not go into an
	// endless loop.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateMenu:) name: nil object: rep];
	return self;
}

// Lazy construction/updating.
- (id) submenu {
	if (![lock tryLock])
		return sub;
		
	if (sub == nil) {
		sub = [[NSMenu alloc] initWithTitle: [repo repository]];
		[sub retain];
		
		// We want to update right now.
		lastUpdate = [NSDate distantPast];
		[lastUpdate retain];
	}
	
	NSTimeInterval interval = -1 * [lastUpdate timeIntervalSinceNow];
	
	// Every one minute, eligible for update.
	if (interval >= 60) {
		dispatch_async(dispatch_get_global_queue(0, 0), ^{
			dispatch_async(dispatch_get_main_queue(), ^{
				[self updateMenu: nil];
				[lock unlock];
			});
		});
	} else {
		[lock unlock];
	}
	
	return sub;
}

- (void) dealloc {
	[super dealloc];
	NSLog(@"Deallocating RepoMenuItem");
}

@end