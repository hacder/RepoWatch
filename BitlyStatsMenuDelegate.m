#import "BitlyStatsButtonDelegate.h"
#import <dispatch/dispatch.h>

@implementation BitlyStatsButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	last_clicks = -1;
	return self;
}

static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

- (NSString *) base64Username: (NSString *)u password: (NSString *)p {
	NSString *realData = [[NSString alloc] initWithFormat: @"%@:%@", u, p];
	if ([realData length] == 0)
		return @"";
	char *characters = malloc(((([realData length] + 2) / 3) * 4) + 1);
	characters[((([realData length] + 2) / 3) * 4)] = '\0';
	NSUInteger length = 0;
	NSUInteger i = 0;
	while (i < [realData length]) {
		char buffer[3] = {0,0,0};
		short bufferLength = 0;
		while (bufferLength < 3 && i < [realData length])
			buffer[bufferLength++] = ((char *)[realData cStringUsingEncoding: NSASCIIStringEncoding])[i++];
		characters[length++] = encodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
		if (bufferLength > 1)
			characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) << 6)];
		else
			characters[length++] = '=';
		if (bufferLength > 2)
			characters[length++] = encodingTable[buffer[2] & 0x3F];
		else
			characters[length++] = '=';
	}
	return [[[NSString alloc] initWithBytesNoCopy: characters length: length encoding: NSASCIIStringEncoding freeWhenDone: YES] autorelease];
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
//	NSString *username = [defaults stringForKey: @"twitterUsername"];
//	NSString *password = [defaults stringForKey: @"twitterPassword"];
	NSString *username = @"codenamebowser";
	NSString *password = @"Joseph1984";

	if (![defaults boolForKey: @"bitlyEnabled"] || username == nil || [username length] == 0 || password == nil || [password length] == 0) {
		[self setTitle: @"Bitly disabled"];
		[self setHidden: YES];
		[self setPriority: -1];
		return;
	}
	[self setHidden: NO];

	NSString *auth = [self base64Username: username password: password];
	
	int count = [[[NSUserDefaults standardUserDefaults] stringForKey: @"bitlyTwitterHistory"] intValue];
	NSURL *url = [[NSURL alloc] initWithString: [[NSString alloc] initWithFormat: @"http://www.twitter.com/statuses/user_timeline.xml?screen_name=%@&count=%d", username, count]];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
	[request setValue: [NSString stringWithFormat: @"Basic %@", auth] forHTTPHeaderField: @"Authorization"];
	
	NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
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
		for (; m < [pieces count]; m++) {
			NSString *tmp = [pieces objectAtIndex: m];
			NSArray *pieces = [tmp componentsSeparatedByCharactersInSet: [[NSCharacterSet alphanumericCharacterSet] invertedSet]];
			NSString *hash = [pieces objectAtIndex: 0];
			
			[self getBitlyInfoWithHash: hash];
			[self setPriority: 16];
			return;
		}
	}
	[self setPriority: 0];
	[self setTitle: @"No bitly links found"];
	[self setHidden: YES];
}

@end