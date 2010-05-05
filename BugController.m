#import "BugController.h"
#import <dispatch/dispatch.h>

@implementation BugController

- (void) awakeFromNib {
	[window setDelegate: self];
}

- (void) windowDidBecomeKey: (NSNotification *)notification {
	NSString *myRequestString = [NSString stringWithFormat: @"uuid=%@",
		[[NSUserDefaults standardUserDefaults] objectForKey: @"UUID"],
		[[bugText string] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
	NSData *data = [NSData
		dataWithBytes: [myRequestString UTF8String]
		length: [myRequestString length]
	];
	NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:
		[NSURL URLWithString: @"http://api.doomstick.com/bug/1/read?project_id=2"]];

	[urlRequest setHTTPMethod: @"POST"];
	[urlRequest setHTTPBody: data];
	[urlRequest retain];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[urlRequest autorelease];
		NSData *data = [NSURLConnection sendSynchronousRequest: urlRequest returningResponse: nil error: nil];
		NSXMLDocument *doc = [[NSXMLDocument alloc] initWithData: data options: (NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA) error: nil];
		NSArray *bugs = [[doc rootElement] nodesForXPath: @".//bug" error: nil];
		[ac addObjects: bugs];
		NSLog(@"Got document %@", bugs);
	});
	
	NSLog(@"Window did become key!");
}

- (IBAction) submitBug: (id) sender {
	[button setEnabled: NO];
	NSString *myRequestString = [NSString stringWithFormat: @"uuid=%@&body=%@&name=hackfornow",
		[[NSUserDefaults standardUserDefaults] objectForKey: @"UUID"],
		[[bugText string] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
	NSData *data = [NSData
		dataWithBytes: [myRequestString UTF8String]
		length: [myRequestString length]
	];
	NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:
		[NSURL URLWithString: @"http://api.doomstick.com/bug/1/write?project_id=2"]];

	[urlRequest setHTTPMethod: @"POST"];
	[urlRequest setHTTPBody: data];
	[urlRequest retain];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[urlRequest autorelease];
		NSData *data = [NSURLConnection sendSynchronousRequest: urlRequest returningResponse: nil error: nil];
		NSString *tmp = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		NSLog(@"Got data: %@", tmp);
		dispatch_async(dispatch_get_main_queue(), ^{
			[bugText setString: @""];
			[button setEnabled: YES];
			[window close];
		});
	});
}

@end