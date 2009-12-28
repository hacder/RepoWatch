#import "RepoButtonDelegate.h"
#import <dispatch/dispatch.h>
#import <sys/time.h>

@implementation RepoButtonDelegate

static NSMutableArray *repos;

void callbackFunction(
		ConstFSEventStreamRef streamRef,
		void *clientCallBackInfo,
		size_t numEvents,
		void *eventPaths,
		const FSEventStreamEventFlags eventFlags[],
		const FSEventStreamEventId eventIds[]) {
	RepoButtonDelegate *rbd = (RepoButtonDelegate *)clientCallBackInfo;
	NSLog(@"Firing on %@", rbd->repository);
	[rbd fire];
}

- (NSString *)shortenDiff: (NSString *)diff {
	NSArray *parts = [diff componentsSeparatedByString: @", "];
	if ([parts count] == 3) {
		NSString *ret = [NSString stringWithFormat: @"%d files, +%d -%d",
			[[parts objectAtIndex: 0] intValue],
			[[parts objectAtIndex: 1] intValue],
			[[parts objectAtIndex: 2] intValue]];
		return ret;
	} else {
		return diff;
	}
}

- (NSString *)stringFromFile: (NSFileHandle *)file {
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[[NSString alloc] initWithData: data
			encoding: NSUTF8StringEncoding] autorelease];
	return string;
}

- (NSArray *)arrayFromResultOfArgs: (NSArray *)args {
	NSTask *t = [[self taskFromArguments: args] autorelease];
	NSFileHandle *file = [self pipeForTask: t];

	@try {
		[t launch];
		
		NSString *string = [self stringFromFile: file];
		NSArray *result = [string componentsSeparatedByString: @"\n"];
		[file closeFile];
		return result;
	} @catch (NSException *e) {
	}
	return nil;
}

- (NSFileHandle *)pipeForTask: (NSTask *)t {
	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	return file;
}

- (void) openInFinder: (id) sender {
	NSTask *t = [self baseTask: @"/usr/bin/open" fromArguments: [NSArray arrayWithObjects: @".", nil]];
	[t autorelease];
	[t launch];
}

- (void) openInTerminal: (id) sender {
	NSString *s = [NSString stringWithFormat: @"tell application \"Terminal\" to do script \"cd '%@'\"", repository];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
	[as executeAndReturnError:nil];
}

- (NSTask *)baseTask: (NSString *)task fromArguments: (NSArray *)args {
	NSTask *t = [[NSTask alloc] init];
	[t setLaunchPath: task];
	[t setCurrentDirectoryPath: repository];
	[t setArguments: args];
	return t;
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	return nil;
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc repository: (NSString *)repo {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc];
	lock = [[NSLock alloc] init];
	localMod = NO;
	upstreamMod = NO;
	
	int size = 10;
	redBubble = [[NSImage alloc] initWithSize: NSMakeSize(size, size)];
	[redBubble lockFocus];
	NSGradient *aGradient = [
		[
			[NSGradient alloc]
				initWithStartingColor: [NSColor colorWithCalibratedRed: 1.0 green: 0.75 blue: 0.75 alpha: 1.0]
				endingColor: [NSColor colorWithCalibratedRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0]
		] autorelease];
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(0, 0, size, size)];
	[aGradient drawInBezierPath: path relativeCenterPosition: NSMakePoint(0.0, 0.0)];
	[redBubble unlockFocus];

	greenBubble = [[NSImage alloc] initWithSize: NSMakeSize(size, size)];
	[greenBubble lockFocus];
	aGradient = [
		[
			[NSGradient alloc]
				initWithStartingColor: [NSColor colorWithCalibratedRed: 0.75 green: 1.0 blue: 0.75 alpha: 1.0]
				endingColor: [NSColor colorWithCalibratedRed: 0.0 green: 1.0 blue: 0.0 alpha: 1.0]
		] autorelease];
	path = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(0, 0, size, size)];
	[aGradient drawInBezierPath: path relativeCenterPosition: NSMakePoint(0.0, 0.0)];
	[greenBubble unlockFocus];

	repository = repo;
	[repository retain];

	if (!repos) {
		repos = [NSMutableArray arrayWithCapacity: 10];
		[repos retain];
	}
	[repos addObject: self];

	FSEventStreamRef stream;
	FSEventStreamContext fsesc = {0, self, NULL, NULL, NULL};
	CFStringRef myPath = (CFStringRef)repository;
	// Leaking this.
	CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&myPath, 1, NULL);
	CFAbsoluteTime latency = 0.0;
	stream = FSEventStreamCreate(NULL,
		&callbackFunction,
		&fsesc,
		pathsToWatch,
		kFSEventStreamEventIdSinceNow,
		latency,
		kFSEventStreamCreateFlagNone | kFSEventStreamCreateFlagWatchRoot
	);
	
	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
	CFRelease(pathsToWatch);

	return self;
}


- (NSString *)getDiff {
	NSArray *arr = [NSArray arrayWithObjects: @"diff", nil];
	NSTask *t = [[self taskFromArguments: arr] autorelease];
	NSFileHandle *file = [self pipeForTask: t];
	[t launch];
	NSString *result = [self stringFromFile: file];
	[file closeFile];
	return result;
}

- (void) beep: (id) something {
	NSLog(@"Beep!");
}

- (void) fire {
}

+ (NSUInteger) numModified {
	NSUInteger ret = 0;
	int i = 0;
	for (i = 0; i < [repos count]; i++) {
		RepoButtonDelegate *rbd = [repos objectAtIndex: i];
		if (rbd->localMod || rbd->upstreamMod)
			ret++;
	}
	return ret;
}

+ (NSUInteger)numLocalEdit {
	NSUInteger ret = 0;
	int i = 0;
	for (i = 0; i < [repos count]; i++) {
		RepoButtonDelegate *rbd = [repos objectAtIndex: i];
		if (rbd->localMod)
			ret++;
	}
	return ret;
}

+ (NSUInteger)numRemoteEdit {
	NSUInteger ret = 0;
	int i = 0;
	for (i = 0; i < [repos count]; i++) {
		RepoButtonDelegate *rbd = [repos objectAtIndex: i];
		if (rbd->upstreamMod)
			ret++;
	}
	return ret;
}

+ (NSUInteger)numUpToDate {
	NSUInteger ret = 0;
	int i = 0;
	for (i = 0; i < [repos count]; i++) {
		RepoButtonDelegate *rbd = [repos objectAtIndex: i];
		if (!rbd->upstreamMod && !rbd->localMod)
			ret++;
	}
	return ret;
}

+ (NSString *) getModText {
	RepoButtonDelegate *rbd = [RepoButtonDelegate getModded];
	if (rbd)
		return rbd->title;
	return nil;
}

+ (RepoButtonDelegate *) getModded {
	int i = 0;
	for (i = 0; i < [repos count]; i++) {
		RepoButtonDelegate *rbd = [repos objectAtIndex: i];
		if (rbd->localMod || rbd->upstreamMod)
			return rbd;
	}
	return nil;
}

+ (BOOL) alreadyHasPath: (NSString *)path {
	int i = 0;
	for (i = 0; i < [repos count]; i++) {
		RepoButtonDelegate *rbd = [repos objectAtIndex: i];
		if ([rbd->repository isEqualToString: path])
			return YES;
	}
	return NO;
}

- (void) commit: (id) menuItem {
}

- (void) clickUpdate: (id) button {
}


@end