#import "TwitterTrendingButtonDelegate.h"

@implementation TwitterTrendingButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	[super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
}

- (void) setupTimer {
	int delay = [[[NSUserDefaults standardUserDefaults] stringForKey: @"trendDelay"] intValue];
	[NSTimer scheduledTimerWithTimeInterval: (1.0 * delay) target: self selector: @selector(fire:) userInfo: nil repeats: YES];
	[self fire: nil];
}

- (void) beep: (id) something {
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection {
}

- (void) fire: (NSTimer *)t {
	NSURL *url = [NSURL URLWithString: @"http://search.twitter.com/trends.json"];
	NSURLRequest *request = [NSURLRequest requestWithURL: url];

	NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
	NSString *result = [[NSString alloc] initWithBytes: [data bytes] length: [data length] encoding: NSUTF8StringEncoding];
	NSArray *results = [result componentsSeparatedByString: @"\"name\":\""];
	NSMutableArray *res = [NSMutableArray arrayWithCapacity: [results count]];
	[res addObjectsFromArray: results];
	[res removeObjectAtIndex: 0];
	
	int i;
	NSMutableString *r = [NSMutableString stringWithCapacity: 10];
	NSMutableString *r2 = [NSMutableString stringWithCapacity: 20];
	
	int num = [[[NSUserDefaults standardUserDefaults] stringForKey: @"shortTwitterTrendCount"] intValue];
	for (i = 0; i < [res count]; i++) {
		NSRange ra = [[res objectAtIndex: i] rangeOfString: @"\""];
		if (i < num) {
			[r appendString: [[[res objectAtIndex: i] substringToIndex: ra.location] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\"#"]]];
			if (i != num - 1)
				[r appendString: @", "];
		}
		[r2 appendString: [[[res objectAtIndex: i] substringToIndex: ra.location] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\"#"]]];
		if (i != [res count] - 1)
			[r2 appendString: @", "];
	}
	
	priority = 15;
	[self setShortTitle: r];
	[self setTitle: r2];
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end