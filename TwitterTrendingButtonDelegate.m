#import "TwitterTrendingButtonDelegate.h"
#import "TwitterTrendView.h"
#import <dispatch/dispatch.h>

@implementation TwitterTrendingButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	return self;
}

- (void) setupTimer {
	int delay = [[[NSUserDefaults standardUserDefaults] stringForKey: @"trendDelay"] intValue];
	[self realTimer: delay];
}

- (void) beep: (id) something {
}

/*
- (void) addMenuItem {
	[super addMenuItem];
	dispatch_async(dispatch_get_main_queue(), ^{
		[menuItem setView: [[TwitterTrendView alloc] initWithFrame: NSMakeRect(0, 0, 100, 50)]];
	});
}
*/

- (void) connectionDidFinishLoading: (NSURLConnection *)connection {
}

- (void) fire {
	NSURL *url = [NSURL URLWithString: @"http://search.twitter.com/trends.json"];
	NSURLRequest *request = [NSURLRequest requestWithURL: url];

	NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
	NSString *result = [[NSString alloc] initWithBytes: [data bytes] length: [data length] encoding: NSUTF8StringEncoding];
	NSArray *results = [result componentsSeparatedByString: @"\"name\":\""];
	NSMutableArray *res = [NSMutableArray arrayWithCapacity: [results count]];
	[res addObjectsFromArray: results];
	[res removeObjectAtIndex: 0];
	
	int i, z = 0;
	NSMutableString *r = [NSMutableString stringWithCapacity: 10];
	NSMutableString *r2 = [NSMutableString stringWithCapacity: 20];
	
	int num = [[[NSUserDefaults standardUserDefaults] stringForKey: @"trendNumber"] intValue];

	NSCharacterSet *cs = [NSCharacterSet characterSetWithCharactersInString: @"\"#"];
	for (i = 0; i < [res count]; i++) {
		NSRange ra = [[res objectAtIndex: i] rangeOfString: @"\""];
		NSString *potential = [[[res objectAtIndex: i] substringToIndex: ra.location] stringByTrimmingCharactersInSet: cs];

		if ([[NSUserDefaults standardUserDefaults] integerForKey: @"trendMundaneFilter"]) {
			if (![potential caseInsensitiveCompare: @"musicmonday"])
				continue;
			if (![potential caseInsensitiveCompare: @"followfriday"])
				continue;
			if (![potential caseInsensitiveCompare: @"goodnight"])
				continue;
			if (![potential caseInsensitiveCompare: @"lmao"])
				continue;
			if (![potential caseInsensitiveCompare: @"follow friday"])
				continue;
			if (![potential caseInsensitiveCompare: @"music monday"])
				continue;
			if (![potential caseInsensitiveCompare: @"TGIF"])
				continue;
		}

		if (z < num) {
			[r appendString: potential];
			if (z < num - 1)
				[r appendString: @", "];
			z++;
		}
		[r2 appendString: potential];
		if (i < [res count] - 1)
			[r2 appendString: @", "];
	}
	
	[self setShortTitle: r];
	[self setTitle: r2];
	[self setPriority: 15];
	
//	[mainController testpopup];
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end