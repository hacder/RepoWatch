#import "BitlyStatsButtonDelegate.h"
#import <dispatch/dispatch.h>

@implementation BitlyStatsButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	last_clicks = -1;
	return self;
}

- (void) getBitlyInfoWithHash: (NSString *)hash {
	[curHash release];
	curHash = hash;
	[curHash retain];
	NSString *tmp_url = @"http://api.bit.ly/stats?format=xml&version=2.0.1&login=negativeview&apiKey=R_04680eb4d134e771a03692efc5bbfada&hash=";
	NSString *real_url = [NSString stringWithFormat: @"%@%@", tmp_url, hash];
	
	NSURL *url = [NSURL URLWithString: real_url];
	NSURLRequest *request = [NSURLRequest requestWithURL: url];
	
	NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];

	NSXMLDocument *doc = [[NSXMLDocument alloc] initWithData: response options: 0 error: nil];
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
		NSBeep();
	last_clicks = clicks;

	NSString *tit = [[NSString alloc] initWithFormat: @"Bitly: %@ %@ clicks, %@ direct", hash, objOneString, objTwoString];
	[self setShortTitle: tit];
	[self setTitle: tit];
}

- (void) setupTimer {
	int delay = [[[NSUserDefaults standardUserDefaults] stringForKey: @"bitlyDelay"] intValue];
	[self realTimer: delay];
}

- (void) beep: (id) something {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@"Trying to do tricky work\n");
		NSWorkspace *workSpace = [NSWorkspace sharedWorkspace];
		NSLog(@"Got workspace %@\n", workSpace);
		NSString *sUrl = [NSString stringWithFormat: @"http://bit.ly/%@%@", curHash, @"+"];
		NSLog(@"Got url %@\n", sUrl);
		NSURL *url = [NSURL URLWithString: sUrl];
		NSLog(@"Got url object %@\n", url);
		[workSpace openURL: url];
		NSLog(@"Done");
	});
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

- (void) fire {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *username = [defaults stringForKey: @"twitterUsername"];
	if (![defaults boolForKey: @"bitlyEnabled"]) {
		[self setTitle: @"Bitly disabled"];
		[self setHidden: YES];
		[self setPriority: -1];
		return;
	}
	
	int count = [[[NSUserDefaults standardUserDefaults] stringForKey: @"bitlyTwitterHistory"] intValue];
	NSData *data = [self fetchDataForURL: [[NSURL alloc] initWithString: [[NSString alloc] initWithFormat: @"http://www.twitter.com/statuses/user_timeline.xml?screen_name=%@&count=%d", username, count]]];
	if (data == nil) {
		[self setPriority: 1];
		[self setTitle: @"Bitly error fetching XML"];
		return;
	}
	NSXMLDocument *doc  = [[NSXMLDocument alloc] initWithData: data options: 0 error: nil];
	NSArray *statuses = [doc objectsForXQuery: @"//text" error: nil];
	NSArray *status_times = [doc objectsForXQuery: @"//status/created_at" error: nil];

	int i = 0;
	count = [[[NSUserDefaults standardUserDefaults] stringForKey: @"bitlyTwitterHistory"] intValue];
	for (; i < [statuses count]; i++) {
		NSDateComponents *components = [[NSDateComponents alloc] init];
		NSArray *stringPieces = [[[status_times objectAtIndex: i] stringValue] componentsSeparatedByString: @" "];
		[components setYear: [[stringPieces objectAtIndex: 5] intValue]];
		[components setDay: [[stringPieces objectAtIndex: 2] intValue]];
		[components setMonth: [self monthNameToInt: [stringPieces objectAtIndex: 1]]];
		stringPieces = [[stringPieces objectAtIndex: 3] componentsSeparatedByString: @":"];
		[components setHour: [[stringPieces objectAtIndex: 0] intValue]];
		[components setMinute: [[stringPieces objectAtIndex: 1] intValue]];
		[components setSecond: [[stringPieces objectAtIndex: 2] intValue]];
		
		NSTimeZone *tz = [NSTimeZone timeZoneWithName: @"GMT"];
		NSCalendar *greg = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
		[greg setTimeZone: tz];
		NSDate *tweetDate = [greg dateFromComponents: components];
		NSTimeInterval timeSince = [tweetDate timeIntervalSinceNow] * -1;
		if (timeSince / 3600 >= 24)
			continue;

		NSString *tweet = [[statuses objectAtIndex: i] stringValue];
		NSRange r = [tweet rangeOfString: @"(via"];
		if (r.location != NSNotFound)
			continue;

		NSArray *pieces = [tweet componentsSeparatedByString: @"//bit.ly/"];
		if ([pieces count] == 1)
			continue;

		int m = 1;
		NSLog(@"Found bitly link, posted %f hours ago", timeSince / 3600);
		for (; m < [pieces count]; m++) {
			NSString *tmp = [pieces objectAtIndex: m];
			NSArray *pieces = [tmp componentsSeparatedByCharactersInSet: [[NSCharacterSet alphanumericCharacterSet] invertedSet]];
			NSString *hash = [pieces objectAtIndex: 0];
			
			[self getBitlyInfoWithHash: hash];
			[self setPriority: 16];
			[self setHidden: NO];
			return;
		}
	}

	[self setTitle: @"No bitly links found"];
	[self setPriority: 0];
	[self setHidden: YES];
}

@end