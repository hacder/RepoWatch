#import "TwitFollowerButtonDelegate.h"
#import <dispatch/dispatch.h>

@implementation TwitFollowerButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	foll = [NSMutableArray arrayWithCapacity: 10];
	return self;
}

- (void) setupTimer {
	[self realTimer: 600];
}

- (void) beep: (id) something {
}

- (void) fire {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *username = [defaults stringForKey: @"twitterUsername"];

	NSData *data = [self fetchDataForURL: [[NSURL alloc] initWithString: [[NSString alloc] initWithFormat: @"http://www.twitter.com/followers/ids.xml?cursor=-1"]]];
	if (data == nil) {
		NSLog(@"TwitFollower data is nil");
		return;
	}
	NSXMLDocument *doc  = [[NSXMLDocument alloc] initWithData: data options: 0 error: nil];
	NSLog(@"Got: %@", doc);

	NSArray *f = [doc objectsForXQuery: @"//id" error: nil];
	NSMutableArray *followers = [NSMutableArray arrayWithCapacity: [f count]];
	[followers addObjectsFromArray: f];
	
	int i = 0;
	for (; i < [foll count]; i++) {
		NSString *oldFollower = [foll objectAtIndex: i];
		
		int m = 0;
		int found_it = 0;
		for (; m < [followers count]; m++) {
			NSString *newFollower = [[followers objectAtIndex: m] stringValue];
			if ([newFollower compare: oldFollower] == NSOrderedSame) {
				[followers removeObjectAtIndex: m];
				found_it = 1;
				break;
			}
		}
		if (!found_it) {
			NSData *data2 = [self fetchDataForURL: [[NSURL alloc] initWithString: [[NSString alloc] initWithFormat: @"http://www.twitter.com/users/show.xml?user_id=%@", oldFollower]]];
			NSXMLDocument *doc2 = [[NSXMLDocument alloc] initWithData: data2 options: 0 error: nil];
			NSArray *arrrrrr = [doc2 objectsForXQuery: @"//following" error: nil];
			NSArray *arr2 = [doc2 objectsForXQuery: @"//name" error: nil];
			if ([@"true" compare: [[arrrrrr objectAtIndex: 0] stringValue]] == NSOrderedSame) {
				NSString *s = [[NSString alloc] initWithFormat: @"Defollowed by %@", [[arr2 objectAtIndex: 0] stringValue]];
				[self setTitle: s];
				[self setShortTitle: s];
				[self setHidden: NO];
				[self setPriority: 20];
				return;
			}
			// oldFollower just removed us!
		}
	}
	for (i = 0; i < [followers count]; i++)
		[foll addObject: [[followers objectAtIndex: i] stringValue]];
	NSLog(@"Count of followers: %d", [foll count]);
	
	[self setHidden: YES];
	[self setTitle: @"Yay"];
	[self setPriority: 1];
}

@end