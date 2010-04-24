#import "MercurialDiffButtonDelegate.h"
#import "BubbleFactory.h"
#import "RepoHelper.h"
#import "MercurialRepository.h"

@implementation MercurialDiffButtonDelegate

- initWithHG: (const char *)hgPath repository: (NSString *)rep {
	hg = hgPath;
	self = [super initWithRepositoryName: rep type: [MercurialRepository sharedInstance]];
	[self fire: nil];
	return self;
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	NSTask *t = [[[NSTask alloc] init] autorelease];
	NSString *lp = [NSString stringWithFormat: @"%s", hg];
	[t setLaunchPath: lp];
	[t setCurrentDirectoryPath: repository];
	[t setArguments: args];

	return t;
}

- (int) logOffset {
	return 3;
}

- (void) updateLogs {
	[logLock lock];
	
	NSArray *arr = [NSArray arrayWithObjects: @"log", @"-l", @"10", @"--template", @"{node|short} {date|hgdate} {desc|firstline}\n", nil];
	NSTask *t = [self taskFromArguments: arr];

	NSFileHandle *file = [RepoHelper pipeForTask: t];
	NSFileHandle *err = [RepoHelper errForTask: t];

	[t launch];
	NSString *string = [RepoHelper stringFromFile: file];
	NSArray *result = [string componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\0"]];
	[t waitUntilExit];
	if ([t terminationStatus] != 0) {
		[logLock unlock];
		return;
	}

	[err closeFile];
	[file closeFile];

	if ([[result objectAtIndex: [result count] - 1] isEqualToString: @""]) {
		NSMutableArray *result2 = [NSMutableArray arrayWithArray: result];
		[result2 removeObjectAtIndex: [result2 count] - 1];
		[result2 retain];
		_logs = result2;
	} else {
		[result retain];
		_logs = result;		
	}

	[logLock unlock];
}

- (void) upstreamUpdate: (id) sender {
	[sender setEnabled: NO];

	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"pull", nil]];

	// We do not care about the return value, really. Except that errors should be handled.
	[tq addTask: t withCallback: ^(NSArray *resultarr){
		[NSApp hide: self];
		[sender setEnabled: YES];
		[self fire: nil];
	}];
}

- (void) pull: (id) menuItem {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"in", @"--template", @"{node|short} {desc}\n", nil]];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		NSArray *arr = [NSArray arrayWithObjects: @"in", @"-p", nil];
		NSTask *t2 = [self taskFromArguments: arr];
		[tq addTask: t2 withCallback: ^(NSArray *resultarr) {
			[NSApp activateIgnoringOtherApps: YES];
		}];
	}];
}

- (void) addAll: (id) button {
	int i;
	for (i = 0; i < [currentUntracked count]; i++) {
		NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"add", [currentUntracked objectAtIndex: i], nil]];
		[tq addTask: t withCallback: nil];
	}
	[self fire: nil];
}

- (void) ignoreAll: (id) button {
	NSString *path = [NSString stringWithFormat: @"%@/%@", repository, @".hgignore"];
	NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath: path];
	if (fh == nil) {
		[@".hgignore\n" writeToFile: path atomically: NO encoding: NSASCIIStringEncoding error: nil];
		fh = [NSFileHandle fileHandleForWritingAtPath: path];
		if (fh == nil)
			return;
	}
	[fh truncateFileAtOffset: [fh seekToEndOfFile]];
	int i;
	for (i = 0; i < [currentUntracked count]; i++) {
		NSString *fileName = [currentUntracked objectAtIndex: i];
		[fh writeData: [fileName dataUsingEncoding: NSUTF8StringEncoding]];
		[fh writeData: [@"\n" dataUsingEncoding: NSASCIIStringEncoding]];
	}
	[fh synchronizeFile];
	[fh closeFile];
	[self fire: nil];
}

- (void)getUntrackedWithCallback: (void (^)(NSArray *))callback {
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"status", @"-u", nil]];
	[tq addTask: t withCallback: ^(NSArray *arr) {
		NSMutableArray *arrmut = [NSMutableArray arrayWithArray: arr];
		int i;
		for (i = 0; i < [arrmut count]; i++) {
			NSMutableString *original = [NSMutableString stringWithString: [arrmut objectAtIndex: i]];
			if ([original characterAtIndex: 0] == '?' && [original characterAtIndex: 1] == ' ') {
				[original deleteCharactersInRange: NSMakeRange(0, 2)];
			}
			if ([original characterAtIndex: 0] == '"' && [original characterAtIndex: [original length] - 1] == '"') {
				[original deleteCharactersInRange: NSMakeRange(0, 1)];
				[original deleteCharactersInRange: NSMakeRange([original length] - 1, 1)];
			}
			[arrmut replaceObjectAtIndex: i withObject: original];
			(callback)(arrmut);
		}
	}];
}

- (void) beep: (id) something {
}

- (void) commit: (id) something {
	if (!localMod)
		return;
	[super commit: something];	
	[NSApp activateIgnoringOtherApps: YES];
}

- (void) clickUpdate: (id) button {
	[NSApp hide: self];
}

- (NSString *) diffStatOfTask: (NSTask *)t {
	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
	
	NSTask *t2 = [[[NSTask alloc] init] autorelease];
	[t2 setLaunchPath: @"/usr/bin/diffstat"];
	[t2 setStandardInput: pipe];
	
	NSPipe *pipe2 = [NSPipe pipe];
	[t2 setStandardOutput: pipe2];
	
	NSFileHandle *file = [pipe2 fileHandleForReading];
	
	[t launch];
	[t2 launch];
	NSData *data = [file readDataToEndOfFile];
	[file closeFile];
	NSCharacterSet *cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	NSString *utf8String = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	NSString *string = [utf8String stringByTrimmingCharactersInSet: cs];

	return string;
}

- (NSString *) lastGoodComponentOfString: (NSString *)s {
	NSArray *arr = [s componentsSeparatedByString: @"\n"];
	NSString *s2 = [arr objectAtIndex: [arr count] - 1];
	s2 = [s2 stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	return s2;
}

- (void) setupUpstream {
	NSArray *arr = [NSArray arrayWithObjects: @"showconfig", @"paths.default", nil];
	NSTask *t = [self taskFromArguments: arr];
	[tq addTask: t withCallback: ^(NSArray *resultarr) {
		if ([resultarr count]) {
			upstreamName = [resultarr objectAtIndex: 0];
			[upstreamName retain];
		} else {
			upstreamName = nil;
		}
	}];
}

- (NSString *)shortTitle {
	return [repository lastPathComponent];
}

- (void) checkLocal: (NSTimer *)ti {
	if (!dirty) {
		[super checkLocal: ti];
		return;
	}
	NSTask *t = [self taskFromArguments: [NSArray arrayWithObjects: @"diff", nil]];
	NSString *localChanges = [self lastGoodComponentOfString: [self diffStatOfTask: t]];
	if (![localChanges isEqual: @"0 files changed"]) {
		[self setLocalMod: YES];
		[localDiffSummary autorelease];
		localDiffSummary = [RepoHelper shortenDiff: localChanges];
		[localDiffSummary retain];
		
		NSArray *arr = [NSArray arrayWithObjects: @"diff", nil];
		NSTask *t = [self taskFromArguments: arr];
		[tq addTask: t withCallback: ^(NSArray *resultarr) {
			[localDiff autorelease];
			localDiff = [RepoHelper colorizedDiffFromArray: resultarr];
			[localDiff retain];
			[super checkLocal: ti];
		}];
	} else {
		[self setLocalMod: NO];
		[super checkLocal: ti];
		[self setDirty: NO];
	}
}

@end