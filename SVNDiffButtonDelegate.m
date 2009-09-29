#import "SVNDiffButtonDelegate.h"

@implementation SVNDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc svnPath: (char *)svnPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	svn = svnPath;
	repository = rep;
	[repository retain];
	timeout = 15;
	[self setupTimer];
	return self;
}

- (void) beep: (id) something {
}

- (void) fire {
	NSTask *t = [[NSTask alloc] init];
	NSString *lp = [NSString stringWithFormat: @"%s", svn];
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
	
			if ([s2 isEqual: @"0 files changed"]) {
				timeout = 15;
				[self setHidden: TRUE];
				[self setPriority: 0];
			} else {
				NSString *sTit = [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], s2];
			
				timeout = 2;
				[self setTitle: sTit];
				[self setShortTitle: sTit];
				[self setHidden: FALSE];
				[self setPriority: 25];
			}
		});
	});
}

@end