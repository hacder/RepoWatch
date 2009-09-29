#import "TwitFollowerButtonDelegate.h"
#import <dispatch/dispatch.h>

@implementation TwitFollowerButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	foll = [NSMutableArray arrayWithCapacity: 10];
	[self setupTimer];
	[self setHidden: YES];
	return self;
}

- (void) beep: (id) something {
	[self setHidden: YES];
	[self setTitle: @"Yay"];
	[self setPriority: 1];
}

- (void) fire {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	timeout = [defaults integerForKey: @"followerDelay"];

	if ([defaults integerForKey: @"defollowEnabled"] == 0 || [defaults integerForKey: @"twitterEnabled"] == 0) {
		[self setTitle: @""];
		[self setShortTitle: @""];
		[self setHidden: YES];
		[self setPriority: 1];
		return;
	}

	NSString *username = [defaults stringForKey: @"twitterUsername"];
	if (username == nil) {
		[self setTitle: @""];
		[self setShortTitle: @""];
		[self setHidden: YES];
		[self setPriority: 1];
		return;
	}

	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSString *fireString = [[[NSString alloc] initWithFormat: @"http://www.twitter.com/followers/ids.xml?cursor=-1"] autorelease];
		NSURL *fireURL = [[[NSURL alloc] initWithString: fireString] autorelease];
		NSData *data = [self fetchDataForURL: fireURL];
		if (data == nil) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[self setTitle: @""];
				[self setShortTitle: @""];
				[self setHidden: YES];
				[self setPriority: 1];
			});
			return;
		}
		[data retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			[data autorelease];
			NSXMLDocument *doc  = [[[NSXMLDocument alloc] initWithData: data options: 0 error: nil] autorelease];
		
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
					NSString *foundString = [[[NSString alloc] initWithFormat: @"http://www.twitter.com/users/show.xml?user_id=%@", oldFollower] autorelease];
					NSData *data2 = [self fetchDataForURL: [[NSURL alloc] initWithString: foundString]];
					NSXMLDocument *doc2 = [[[NSXMLDocument alloc] initWithData: data2 options: 0 error: nil] autorelease];
					NSArray *arrrrrr = [doc2 objectsForXQuery: @"//following" error: nil];
					NSArray *arr2 = [doc2 objectsForXQuery: @"//name" error: nil];
					if ([arrrrrr count] == 0 || [arr2 count] == 0)
						return;
					if ([@"true" compare: [[arrrrrr objectAtIndex: 0] stringValue]] == NSOrderedSame) {
						NSString *s = [[[NSString alloc] initWithFormat: @"Defollowed by %@", [[arr2 objectAtIndex: 0] stringValue]] autorelease];
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
			
			[self setHidden: YES];
			[self setTitle: @"Yay"];
			[self setPriority: 1];
		});
	});
}

@end