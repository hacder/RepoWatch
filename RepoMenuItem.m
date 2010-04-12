#import "RepoMenuItem.h"

@implementation RepoMenuItem

- (void) updateMenu: (NSNotification *)notif {
	[sub removeAllItems];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setDoesRelativeDateFormatting:YES];

	NSDictionary *dateAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor grayColor],
		NSForegroundColorAttributeName,
		[NSFont labelFontOfSize: 10],
		NSFontAttributeName,
		nil];
	NSDictionary *logAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSColor blackColor],
		NSForegroundColorAttributeName,
		[NSFont systemFontOfSize: 14],
		NSFontAttributeName,
		nil];

 	NSArray *logs = [repo logs];
	int i;
	NSMenuItem *mi;
	for (i = 0; i < [logs count]; i++) {
		NSString *currentPiece = [logs objectAtIndex: i];
		NSArray *pieces = [currentPiece componentsSeparatedByString: @" "];
		NSString *timestamp = [pieces objectAtIndex: 1];
		NSString *hash = [pieces objectAtIndex: 2];
		NSRange theRange;
		theRange.location = 2;
		theRange.length = [pieces count] - 2;
		
		NSArray *logMessage = [pieces subarrayWithRange: theRange];
		NSString *logString = [NSString stringWithFormat: @" %@", [logMessage componentsJoinedByString: @" "]];
		NSString *dateString = [dateFormatter stringFromDate: [NSDate dateWithTimeIntervalSince1970: [timestamp intValue]]];
		NSMutableAttributedString *dateAttrString = [[NSMutableAttributedString alloc] initWithString: dateString attributes: dateAttributes];
		[dateAttrString appendAttributedString: [[NSAttributedString alloc] initWithString: logString attributes: logAttributes]];
		
		NSString *title = [NSString stringWithFormat: @"%@ %@", dateString, logString];
		mi = [sub addItemWithTitle: title action: nil keyEquivalent: @""];
		[mi setAttributedTitle: dateAttrString];
		[mi setToolTip: logString];
		[mi setRepresentedObject: hash];
	}
	
	if ([repo hasUntracked] || [repo hasLocal] || [repo hasUpstream])
		[sub addItem: [NSMenuItem separatorItem]];
	
	if ([repo hasLocal]) {
		mi = [sub addItemWithTitle: @"Commit Local Changes" action: @selector(commitFromMenu:) keyEquivalent: @""];
		[mi setRepresentedObject: repo];
		[mi setTarget: [MainController sharedInstance]];
	}
	
	[lastUpdate release];
	lastUpdate = [NSDate date];
	[lastUpdate retain];	
}

- (id) initWithRepository: (RepoButtonDelegate *)rep {
	self = [super initWithTitle: [rep shortTitle] action: nil keyEquivalent: @""];
	repo = rep;
	[repo retain];
	[self setToolTip: [repo repository]];
	
	// Update the menu no matter what the notification is. We may have to filter some out later on to not go into an
	// endless loop.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateMenu:) name: nil object: rep];
	return self;
}

// Lazy construction/updating.
- (id) submenu {
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
			});
		});
	}
	
	return sub;
}

@end