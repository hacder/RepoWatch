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

// Crashed somewhere in this function without debug info.	
- (NSFileHandle *)pipeForTask: (NSTask *)t {
	// This sometimes returns nil?!
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

- (void) fire {
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects:
				@"diff", @"--shortstat", nil]] autorelease];
		NSFileHandle *file = [self pipeForTask: t];

		@try {
			[t launch];
		} @catch (NSException *e) {
			timeout = -1;
			[self setTitle: @"Errored"];
			[self setHidden: YES];
			[self setPriority: 1];
			return;
		}
		NSString *string = [self stringFromFile: file];
		[file closeFile];
		
		if ([string isEqual: @""] && !watchHash) {
			dispatch_async(dispatch_get_main_queue(), ^{
				timeout = 15;
				NSString *s3 = [NSString stringWithFormat: @"git: %@",
						[repository lastPathComponent]];
				[self setTitle: s3];
				[self setShortTitle: s3];
				[self setHidden: NO];
				[self setPriority: 1];
			});
		} else {
			if ([string isEqual: @""]) {
				NSTask *t2 = [self taskFromArguments: [NSArray arrayWithObjects:
						@"diff", @"--shortstat", watchHash, nil]];
				NSFileHandle *f2 = [self pipeForTask: t2];
				dispatch_async(dispatch_get_main_queue(), ^{
					[t2 autorelease];
					[t2 launch];
					timeout = 15;
				
					NSString *s2 = [self stringFromFile: f2];
					[f2 closeFile];
					NSString *st = [NSString stringWithFormat: @"%@ (%@): %@",
							[repository lastPathComponent], watchHash,
							[s2 isEqual: @""] ? @"no changes" :
							[s2 stringByTrimmingCharactersInSet:
							[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
					[self setShortTitle: st];
					[self setTitle: st];
					[self setHidden: NO];
					[self setPriority: 15];
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
		}
	});
}

@end