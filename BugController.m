#import "BugController.h"
#import "ThreadCounter.h"
#import <dispatch/dispatch.h>

@implementation BugController

- (id) init {
	self = [super init];
	return self;
}

- (IBAction) submitBug: (id) sender {
	[button setEnabled: NO];
	NSString *myRequestString = [NSString stringWithFormat: @"uuid=%@&body=%@", [[NSUserDefaults standardUserDefaults] objectForKey: @"UUID"], [[bugText string] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
	NSData *data = [NSData
		dataWithBytes: [myRequestString UTF8String]
		length: [myRequestString length]
	];
	NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: @"http://www.doomstick.com/blog/projects/repowatch/bugs/"]];
	[urlRequest setHTTPMethod: @"POST"];
	[urlRequest setHTTPBody: data];
	[urlRequest retain];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[ThreadCounter enterSection];
		[urlRequest autorelease];
		[NSURLConnection sendSynchronousRequest: urlRequest returningResponse: nil error: nil];
		dispatch_async(dispatch_get_main_queue(), ^{
			[bugText setString: @""];
			[button setEnabled: YES];
			[window close];
		});
		[ThreadCounter exitSection];
	});
}

@end