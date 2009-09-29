#import "BitlyStatsButtonDelegate.h"
#import <dispatch/dispatch.h>

@implementation BitlyStatsButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	last_clicks = -1;
	greg = [[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar] autorelease];
	NSTimeZone *tz = [NSTimeZone timeZoneWithName: @"GMT"];
	[greg setTimeZone: tz];
	[self setupTimer];
	return self;
}

- (void) getBitlyInfoWithHash: (NSString *)hash {
	[curHash release];
	curHash = hash;
	[curHash retain];
	NSString *tmp_url = @"http://api.bit.ly/stats?format=xml&version=2.0.1&login=negativeview&apiKey=R_04680eb4d134e771a03692efc5bbfada&hash=";
	NSString *real_url = [NSString stringWithFormat: @"%@%@", tmp_url, hash];
	
	NSURL *url = [NSURL URLWithString: real_url];
	NSURLRequest *request = [[NSURLRequest requestWithURL: url] retain];
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[request autorelease];
		NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
		NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithData: response options: 0 error: nil] autorelease];
		NSArray *counts = [doc objectsForXQuery: @"//clicks" error: nil];
		NSArray *directs = [doc objectsForXQuery: @"//direct" error: nil];
	
		if (counts == nil)
			return;
		if ([counts count] == 0)
			return;

		NSString *objOneString = [[counts objectAtIndex: 0] stringValue];
		NSString *objTwoString = [[directs objectAtIndex: 0] stringValue];

		int clicks = [objTwoString intValue];
		if (last_clicks != -1 && last_clicks != clicks)
			if ([[[NSUserDefaults standardUserDefaults] stringForKey: @"bitlyBeep"] intValue] == 1)
				NSBeep();
		last_clicks = clicks;

		NSString *tit = [[[NSString alloc] initWithFormat: @"Bitly: %@ %@ clicks, %@ direct", hash, objOneString, objTwoString] autorelease];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setShortTitle: tit];
			[self setTitle: tit];
			[self setHidden: NO];
			[self setPriority: 16];
		});
	});
}

- (void) beep: (id) something {
	NSWorkspace *workSpace = [NSWorkspace sharedWorkspace];
	NSString *sUrl = [NSString stringWithFormat: @"http://bit.ly/%@%@", curHash, @"+"];
	NSURL *url = [NSURL URLWithString: sUrl];
	[workSpace openURL: url];
}

- (int) monthNameToInt: (NSString *)name {
	if ([name isEqualToString: @"Jan"])
		return 1;
	if ([name isEqualToString: @"Feb"])
		return 2;
	if ([name isEqualToString: @"Mar"])
		return 3;
	if ([name isEqualToString: @"Apr"])
		return 4;
	if ([name isEqualToString: @"May"])
		return 5;
	if ([name isEqualToString: @"Jun"])
		return 6;
	if ([name isEqualToString: @"Jul"])
		return 7;
	if ([name isEqualToString: @"Aug"])
		return 8;
	if ([name isEqualToString: @"Sep"])
		return 9;
	if ([name isEqualToString: @"Oct"])
		return 10;
	if ([name isEqualToString: @"Nov"])
		return 11;
	if ([name isEqualToString: @"Dec"])
		return 12;
	return 0;
}

- (NSXMLDocument *) testingStupidGCStuff: (NSData *)data {
	NSXMLDocument *doc = [[[NSXMLDocument alloc] initWithData: data options: 0 error: nil] autorelease];
	return doc;
}

- (NSDateComponents *)getDateComponentsFromString: (NSString *)s {
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	NSArray *stringPieces = [s componentsSeparatedByString: @" "];
	[components setYear: [[stringPieces objectAtIndex: 5] intValue]];
	[components setDay: [[stringPieces objectAtIndex: 2] intValue]];
	[components setMonth: [self monthNameToInt: [stringPieces objectAtIndex: 1]]];
	stringPieces = [[stringPieces objectAtIndex: 3] componentsSeparatedByString: @":"];
	[components setHour: [[stringPieces objectAtIndex: 0] intValue]];
	[components setMinute: [[stringPieces objectAtIndex: 1] intValue]];
	[components setSecond: [[stringPieces objectAtIndex: 2] intValue]];
	return components;
}

- (void) fire {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	timeout = [[[NSUserDefaults standardUserDefaults] stringForKey: @"bitlyDelay"] intValue];

	if ([defaults integerForKey: @"bitlyEnabled"] == 0 || [defaults integerForKey: @"twitterEnabled"] == 0) {
		[self setHidden: YES];
		[self setTitle: @"Bitly disabled"];
		[self setPriority: -1];
		return;
	}
	
	NSString *username = [defaults stringForKey: @"twitterUsername"];
	int count = [[[NSUserDefaults standardUserDefaults] stringForKey: @"bitlyTwitterHistory"] intValue];
	NSString *urlString = [[[NSString alloc] initWithFormat: @"http://www.twitter.com/statuses/user_timeline.xml?screen_name=%@&count=%d", username, count] autorelease];
	NSURL *fireURL = [[NSURL alloc] initWithString: urlString];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[fireURL autorelease];
		NSData *data = [[self fetchDataForURL: fireURL] retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			[data autorelease];
			if (data == nil) {
				[self setHidden: YES];
				[self setTitle: @"Bitly error fetching XML"];
				[self setPriority: 1];
				return;
			}
			
			NSXMLDocument *doc  = [self testingStupidGCStuff: data];
			NSArray *statuses = [doc objectsForXQuery: @"//text" error: nil];
			NSArray *status_times = [doc objectsForXQuery: @"//status/created_at" error: nil];
		
			int i = 0;
			for (; i < [statuses count]; i++) {
				NSDateComponents *components = [self getDateComponentsFromString: [[status_times objectAtIndex: i] stringValue]];
				NSDate *tweetDate = [greg dateFromComponents: components];
				
				NSTimeInterval timeSince = [tweetDate timeIntervalSinceNow] * -1;
				if (timeSince / 3600 >= [defaults integerForKey: @"bitlyTimeout"])
					continue;
		
				NSString *tweet = [[statuses objectAtIndex: i] stringValue];
				NSRange r = [tweet rangeOfString: @"(via"];
				if (r.location != NSNotFound)
					continue;
		
				NSArray *pieces = [tweet componentsSeparatedByString: @"//bit.ly/"];
				if ([pieces count] == 1)
					continue;
		
				if ([pieces count] > 1) {
					NSString *tmp = [pieces objectAtIndex: 1];
					NSArray *pieces = [tmp componentsSeparatedByCharactersInSet: [[NSCharacterSet alphanumericCharacterSet] invertedSet]];
					NSString *hash = [pieces objectAtIndex: 0];
					
					[self getBitlyInfoWithHash: hash];
					return;
				}
			}
		
			[self setTitle: @"No bitly links found"];
			[self setPriority: 0];
			[self setHidden: YES];
		});
	});
}

@end