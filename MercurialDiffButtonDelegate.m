#import "MercurialDiffButtonDelegate.h"

@implementation MercurialDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc hgPath: (char *)hgPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	hg = hgPath;
	repository = rep;
	[repository retain];
	return self;
}

- (void) setupTimer {
	[self realTimer: 10];
}

- (void) beep: (id) something {
}

- (void) fire {
	NSTask *t = [[NSTask alloc] init];
	NSString *lp = [[NSString stringWithFormat: @"%s", hg] autorelease];
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
		
	[t launch];
	[t2 launch];
		
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSArray *arr = [string componentsSeparatedByString: @"\n"];
	string = [arr objectAtIndex: [arr count] - 1];
	string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

	if ([string isEqual: @"0 files changed"]) {
		[self setHidden: TRUE];
		[self setPriority: 0];
	} else {
		NSString *sTit = [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], string];
	
		[self setTitle: sTit];
		[self setShortTitle: sTit];
		[self setHidden: FALSE];
		[self setPriority: 10];
	}
//	[t release];
//	[t2 release];
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end