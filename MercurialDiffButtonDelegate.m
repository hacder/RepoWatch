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

- (void) commit: (id) something {
	if (!localMod)
		return;
	[super commit: something];	
	[NSApp activateIgnoringOtherApps: YES];
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

@end