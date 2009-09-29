#import "GitDiffButtonDelegate.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc gitPath: (char *)gitPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	git = gitPath;
	repository = rep;
	[repository retain];
	timeout = 15;
	
	int doTagging = [[NSUserDefaults standardUserDefaults] integerForKey: @"gitTagOnClick"];
	if (doTagging) {
		NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"gitTags"];
		if (dict) {
			NSString *tag = [dict objectForKey: repository];
			if (tag) {
				watchHash = tag;
				[watchHash retain];
			}
		}
	}
	
	[self setupTimer];
	return self;
}

- (void) beep: (id) something {
	int doTagging = [[NSUserDefaults standardUserDefaults] integerForKey: @"gitTagOnClick"];
	NSLog(@"doTagging: %d", doTagging);
	if (!doTagging)
		return;
	
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	[dict addEntriesFromDictionary: [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"gitTags"]];
	
	if (watchHash) {
		[watchHash release];
		watchHash = nil;
		if (dict) {
			[dict removeObjectForKey: repository];
			[dict autorelease];
		}
		[self fire];
	} else {
		NSTask *t = [[NSTask alloc] init];
		NSString *lp = [NSString stringWithFormat: @"%s", git];
		[t setLaunchPath: lp];
		[t setCurrentDirectoryPath: repository];
		[t setArguments: [NSArray arrayWithObjects: @"log", @"--max-count=1", @"--pretty=format:%h", nil]];
		
		NSPipe *pipe = [NSPipe pipe];
		[t setStandardOutput: pipe];
	
		dispatch_async(dispatch_get_global_queue(0, 0), ^{
			[dict autorelease];
			[t autorelease];
			[t launch];
		
			NSFileHandle *file = [pipe fileHandleForReading];
			NSData *data = [file readDataToEndOfFile];
	
			NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	
			// Otherwise, there is a race condition with fire, when it's reading this value.
			// Poor man's locking.
			[dict setObject: string forKey: repository];
			[[NSUserDefaults standardUserDefaults] setObject: dict forKey: @"gitTags"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			dispatch_async(dispatch_get_main_queue(), ^{
				if (watchHash)
					[watchHash release];
				watchHash = string;
				[self fire];
			});
		});
	}
}

- (void) fire {
	NSTask *t = [[NSTask alloc] init];
	NSString *lp = [NSString stringWithFormat: @"%s", git];
	[t setLaunchPath: lp];
	[t setCurrentDirectoryPath: repository];
	if (watchHash)
		[t setArguments: [NSArray arrayWithObjects: @"diff", @"--shortstat", watchHash, nil]];
	else
		[t setArguments: [NSArray arrayWithObjects: @"diff", @"--shortstat", nil]];

	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
		
	NSFileHandle *file = [pipe fileHandleForReading];
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[t autorelease];
		[t launch];
		NSData *data = [file readDataToEndOfFile];
		NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		dispatch_async(dispatch_get_main_queue(), ^{
			[string autorelease];
			if ([string isEqual: @""]) {
				timeout = 15;
				[self setHidden: TRUE];
				[self setPriority: 0];
			} else {
				NSString *sTit;
				if (watchHash)
					sTit = [NSString stringWithFormat: @"%@ (%@): %@", [repository lastPathComponent], watchHash, [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
				else
					sTit = [NSString stringWithFormat: @"%@: %@", [repository lastPathComponent], [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	
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