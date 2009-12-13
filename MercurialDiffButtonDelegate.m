#import "MercurialDiffButtonDelegate.h"

@implementation MercurialDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc hgPath: (char *)hgPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mc repository: rep];
	hg = hgPath;
	[self fire];
	return self;
}

- (void) beep: (id) something {
}

- (void) fire {
	NSTask *t = [[NSTask alloc] init];
	NSString *lp = [NSString stringWithFormat: @"%s", hg];
	[t setLaunchPath: lp];
	[t setCurrentDirectoryPath: repository];
	[t setArguments: [NSArray arrayWithObjects: @"diff", nil]];

	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
	
	NSTask *t2 = [[NSTask alloc] init];
	[t2 setLaunchPath: @"/usr/bin/diffstat"];
	[t2 setStandardInput: pipe];
	
	NSPipe *pipe2 = [NSPipe pipe];
	[t2 setStandardOutput: pipe2];
		
	NSFileHandle *file = [pipe2 fileHandleForReading];

	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[t autorelease];
		[t2 autorelease];
		
		[t launch];
		[t2 launch];
		
		NSData *data = [file readDataToEndOfFile];
		NSString *string = [[[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		dispatch_async(dispatch_get_main_queue(), ^{
			[string autorelease];

			NSArray *arr = [string componentsSeparatedByString: @"\n"];
			NSString *s2 = [arr objectAtIndex: [arr count] - 1];
			s2 = [s2 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
			if (![s2 isEqual: @"0 files changed"]) {
				localMod = YES;
				NSString *sTit = [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], s2];
			
				[self setTitle: sTit];
				[self setShortTitle: sTit];
			} else {
				localMod = NO;
				NSLog(@"In else: %@", s2);
			}
		});
	});
}

@end