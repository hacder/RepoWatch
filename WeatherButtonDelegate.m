#import "WeatherButtonDelegate.h"

@implementation WeatherButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	return self;
}

- (void) setupTimer {
	// NOAA only updates once per hour.
	[self realTimer: 3610];
	[self setHidden: YES];
}

- (void) beep: (id) something {
}

- (int) getIntFromDoc: (NSXMLDocument *)doc withKey: (NSString *)key {
	NSArray *s = [doc nodesForXPath: key error: nil];
	if ([s count] != 1)
		return -1;
	
	NSXMLNode *tempNode = [s objectAtIndex: 0];
	NSArray *tmpValue = [tempNode nodesForXPath: @".//value" error: nil];
	if ([tmpValue count] != 1)
		return -1;
	return [[[tmpValue objectAtIndex: 0] stringValue] intValue];	
}

- (void) fire {
	int zip = [[NSUserDefaults standardUserDefaults] integerForKey: @"zipcode"];
	if (zip == 0) {
		[self setHidden: YES];
		[self setTitle: @"Go away"];
		[self setPriority: 1];
		return;
	}
	
	NSDate *now = [NSDate date];
	NSDate *hourAgo = [NSDate dateWithTimeIntervalSinceNow: 3600];
	NSDateComponents *nowComponents = [[NSCalendar currentCalendar] components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate: now];
	NSDateComponents *hourAgoComponents = [[NSCalendar currentCalendar] components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit fromDate: hourAgo];
	
	NSString *urlString = [[[NSString alloc] initWithFormat:
		@"http://www.weather.gov/forecasts/xml/sample_products/browser_interface/ndfdXMLclient.php?zipCodeList=%d&product=time-series&temp=temp&pop12=pop12&wwa=wwa&ptornado=ptornado&begin=%04d-%02d-%02dT%02d:00Z&end=%04d-%02d-%02dT%02d:00dZ",
			zip,
			[nowComponents year], [nowComponents month], [nowComponents day], [nowComponents hour],
			[hourAgoComponents year], [hourAgoComponents month], [hourAgoComponents day], [hourAgoComponents hour]
		] autorelease];
	NSURL *url = [[NSURL URLWithString: urlString] autorelease];
	
	NSURLRequest *request = [NSURLRequest requestWithURL: url];
	NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
	if (data == nil) {
		[self setHidden: YES];
		return;
	}
	
	NSXMLDocument *doc  = [[[NSXMLDocument alloc] initWithData: data options: 0 error: nil] autorelease];
	int temperature = [self getIntFromDoc: doc withKey: @"//temperature"];
	int precip = [self getIntFromDoc: doc withKey: @"//probability-of-precipitation"];
	if (temperature == -1 && precip == -1) {
		// Something bad happened
		[self setHidden: YES];
		return;
	}
	
	NSPredicate *pred = [NSPredicate predicateWithBlock: ^(id evaluatedObject, NSDictionary *bindings) {
		if ([evaluatedObject stringValue] != nil && [[evaluatedObject stringValue] length] != 0)
			return YES;
		return NO;
	}];
	NSArray *s = [[doc nodesForXPath: @"//hazards/hazard-conditions/hazard/@phenomena" error: nil] filteredArrayUsingPredicate: pred];
	NSArray *s2 = [[doc nodesForXPath: @"//hazards/hazard-conditions/hazard/@significance" error: nil] filteredArrayUsingPredicate: pred];
	
	NSString *t;
	if ([s count] == 0) {
		t = [[NSString stringWithFormat: @"Temp: %dF Precip: %d%%", temperature, precip] autorelease];
		[self setTitle: t];
		[self setShortTitle: t];
		[self setHidden: NO];
		[self setPriority: 2];
	} else if ([s count] == 1) {
		// Pull full info in full title
		t = [[NSString stringWithFormat: @"WARNING: %@ %@", [[s objectAtIndex: 0] stringValue], [[s2 objectAtIndex: 0] stringValue]] autorelease];
		[self setTitle: t];
		[self setShortTitle: t];
		[self setHidden: NO];
		[self setPriority: 30];
	} else {
		// Put full info, including the multiple warnings in the full title.
		t = [[NSString stringWithFormat: @"WARNING: %d weather events!", [s count]] autorelease];
		[self setTitle: t];
		[self setShortTitle: t];
		[self setHidden: NO];
		[self setPriority: 30];
	}
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end