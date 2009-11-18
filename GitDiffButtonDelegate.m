#import "GitDiffButtonDelegate.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc
		statusItem: (NSStatusItem *)si mainController: (MainController *)mc
		gitPath: (char *)gitPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m script: sc statusItem: si
			mainController: mc];
	git = gitPath;
	repository = rep;
	[repository retain];
	timeout = 15;
	
	[self setHidden: YES];
	
	[self setupTimer];
	return self;
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	NSTask *t = [[NSTask alloc] init];
	NSString *lp = [NSString stringWithFormat: @"%s", git];
	[t setLaunchPath: lp];
	[t setCurrentDirectoryPath: repository];
	[t setArguments: args];

	return t;
}

- (NSFileHandle *)pipeForTask: (NSTask *)t {
	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	return file;
}

- (NSString *)stringFromFile: (NSFileHandle *)file {
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[[NSString alloc] initWithData: data
			encoding: NSUTF8StringEncoding] autorelease];
	return string;
}

- (NSString *) getDiff {
	NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"diff", @"--shortstat", nil]] autorelease];
	NSFileHandle *file = [self pipeForTask: t];
	
	@try {
		[t launch];
	} @catch (NSException *e) {
		timeout = -1;
		[self setTitle: @"Errored"];
		[self setHidden: YES];
		[self setPriority: -1];
		return nil;
	}
	
	NSString *string = [self stringFromFile: file];
	[file closeFile];
	
	return string;
}

- (void) fire {
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSString *string = [self getDiff];
		if (string == nil && priority == -1)
			return;

		if ([string isEqual: @""]) {
			NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"branch", nil]] autorelease];
			NSFileHandle *file = [self pipeForTask: t];
			// TODO: Wrap in try/catch
			[t launch];
			
			NSString *string = [self stringFromFile: file];
			NSArray *branches = [string componentsSeparatedByString: @"\n"];
			
			int i;
			for (i = 0; i < [branches count]; i++) {
				NSLog(@"%c is at 0", [[branches objectAtIndex: i] characterAtIndex: 0]);
				NSString *tmp = [[branches objectAtIndex: i] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @" \n*\r"]];
				NSLog(@"Branch: (%@) %@", repository, tmp);
			}
			
			[file closeFile];

			dispatch_async(dispatch_get_main_queue(), ^{
				timeout = 15;
				NSString *s3 = [NSString stringWithFormat: @"git: %@ (%@)",
						repository, string];
				[self setTitle: s3];
				[self setShortTitle: s3];
				[self setHidden: NO];
				[self setPriority: 1];
			});
		} else {
			NSString *sTit = [NSString stringWithFormat: @"%@: %@",
					[repository lastPathComponent],
					[string stringByTrimmingCharactersInSet:
					[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			dispatch_async(dispatch_get_main_queue(), ^{
				timeout = 5;
				[self setTitle: sTit];
				[self setShortTitle: sTit];
				[self setHidden: NO];
				[self setPriority: 25];
			});
		}
	});
}

@end