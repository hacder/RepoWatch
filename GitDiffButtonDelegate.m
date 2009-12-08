#import "GitDiffButtonDelegate.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc gitPath: (char *)gitPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mc];
	git = gitPath;
	repository = rep;
	[repository retain];
	
	[self setHidden: YES];
	
	[self setupTimer];
	
	return self;
}

- (void) addMenuItem {
	[super addMenuItem];
	[menuItem setToolTip: repository];
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
		[self setTitle: @"Errored"];
		[self setHidden: YES];
		localMod = NO;
		upstreamMod = NO;
		return nil;
	}
	
	NSString *string = [self stringFromFile: file];
	[file closeFile];
	
	return string;
}

- (void) fire {
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSString *string = [self getDiff];
		if (string == nil)
			return;

		NSTask *t = [[self taskFromArguments: [NSArray arrayWithObjects: @"branch", nil]] autorelease];
		NSFileHandle *file = [self pipeForTask: t];
		// TODO: Wrap in try/catch
		[t launch];
		
		NSString *string2 = [self stringFromFile: file];
		NSArray *branches = [string2 componentsSeparatedByString: @"\n"];
		
		int i;
		for (i = 0; i < [branches count]; i++) {
			NSString *tmp = [branches objectAtIndex: i];
			if (tmp && [tmp length] > 0) {
				if ('*' == [tmp characterAtIndex: 0]) {
					tmp = [tmp stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @" \n*\r"]];
					[currentBranch autorelease];
					currentBranch = tmp;
					[currentBranch retain];
				} else {
					tmp = [tmp stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @" \n*\r"]];
				}
			}
		}
		
		[file closeFile];

		if ([string isEqual: @""]) {
			localMod = NO;
			dispatch_async(dispatch_get_main_queue(), ^{
				NSString *s3;
				if (currentBranch == nil || [currentBranch isEqual: @"master"]) {
					s3 = [NSString stringWithFormat: @"git: %@",
						[repository lastPathComponent]];
				} else {
					s3 = [NSString stringWithFormat: @"git: %@ (%@)",
							[repository lastPathComponent], currentBranch];
				}
				[self setTitle: s3];
				[self setShortTitle: s3];
				[self setHidden: NO];
			});
		} else {
			NSString *sTit;
			localMod = YES;
			if (currentBranch == nil || [currentBranch isEqual: @"master"]) {
				sTit = [NSString stringWithFormat: @"%@: %@",
					[repository lastPathComponent],
					[string stringByTrimmingCharactersInSet:
						[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			} else {
				sTit = [NSString stringWithFormat: @"%@: %@ (%@)",
					[repository lastPathComponent],
					[string stringByTrimmingCharactersInSet:
					[NSCharacterSet whitespaceAndNewlineCharacterSet]], currentBranch];
			}
			dispatch_async(dispatch_get_main_queue(), ^{
				[self setTitle: sTit];
				[self setShortTitle: sTit];
				[self setHidden: NO];
			});
		}
	});
}

@end