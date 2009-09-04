#import "WeatherButtonDelegate.h"

@implementation WeatherButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	[super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
}

- (void) setupTimer {
	// NOAA only updates once per hour.
	[self realTimer: 3600];
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
	NSURL *url = [NSURL URLWithString: @"http://www.weather.gov/forecasts/xml/sample_products/browser_interface/ndfdXMLclient.php?zipCodeList=35805&product=time-series&begin=2009-09-03T22:26Z&end=2009-09-03T23:59Z&temp=temp&pop12=pop12&wwa=wwa&ptornado=ptornado"];
	NSURLRequest *request = [NSURLRequest requestWithURL: url];
	NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
	if (data == nil) {
		[self setHidden: YES];
		return;
	}
	
	NSXMLDocument *doc  = [[NSXMLDocument alloc] initWithData: data options: 0 error: nil];
	NSLog(@"weather xml: %@\n", doc);
	int temperature = [self getIntFromDoc: doc withKey: @"//temperature"];
	int precip = [self getIntFromDoc: doc withKey: @"//probability-of-precipitation"];
	NSLog(@"Temp: %d Precip: %d%%\n", temperature, precip);
	
	NSPredicate *pred = [NSPredicate predicateWithBlock: ^(id evaluatedObject, NSDictionary *bindings) {
		if ([evaluatedObject stringValue] != nil && [[evaluatedObject stringValue] length] != 0)
			return YES;
		return NO;
	}];
	NSArray *s = [[doc nodesForXPath: @"//hazards/hazard-conditions" error: nil] filteredArrayUsingPredicate: pred];
	
	NSString *t = [NSString stringWithFormat: @"Temp: %dF Precip: %d%%%@", temperature, precip, [s count] == 0 ? @"" : @" Warnings!"];
	if ([s count])
		priority = 29;
	else
		priority = 2;
	[self setTitle: t];
	[self setShortTitle: t];
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end