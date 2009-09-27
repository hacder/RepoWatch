#import "GitDiffButtonDelegate.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc gitPath: (char *)gitPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	git = gitPath;
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
	NSTask *t = [[[NSTask alloc] init] autorelease];
	NSString *lp = [NSString stringWithFormat: @"%s", git];
	[t setLaunchPath: lp];
	[t setCurrentDirectoryPath: repository];
	[t setArguments: [NSArray arrayWithObjects: @"diff", @"--shortstat", nil]];

	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
		
	NSFileHandle *file = [pipe fileHandleForReading];
		
	[t launch];
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	if ([string isEqual: @""]) {
		[self setHidden: TRUE];
		[self setPriority: 0];
	} else {
		NSString *sTit = [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	
		[self setTitle: sTit];
		[self setShortTitle: sTit];
		[self setHidden: FALSE];
		[self setPriority: 25];
	}
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end