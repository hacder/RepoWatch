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
	char **ep = (char **)eventPaths;
	int i;
	for (i = 0; i < numEvents; i++) {
		NSLog(@"Event %d of %d was for file %s", i + 1, numEvents, ep[i]);
	}
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

- (void) ignore: (id) sender {
	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [d dictionaryForKey: @"ignoredRepos"];
	NSMutableDictionary *dict2;
	if (dict) {
		dict2 = [NSMutableDictionary dictionaryWithDictionary: dict];
	} else {
		dict2 = [[NSMutableDictionary alloc] initWithCapacity: 1];
	}
	[dict2 setObject: [NSMutableDictionary dictionaryWithCapacity: 1] forKey: repository];
	[d setObject: dict2 forKey: @"ignoredRepos"];

	dict = [d dictionaryForKey: @"cachedRepos"];
	if (dict) {
		dict2 = [NSMutableDictionary dictionaryWithDictionary: dict];
		[dict2 removeObjectForKey: repository];
		[d setObject: dict2 forKey: @"cachedRepos"];
	}
	
	dict = [d dictionaryForKey: @"manualRepos"];
	if (dict) {
		dict2 = [NSMutableDictionary dictionaryWithDictionary: dict];
		[dict2 removeObjectForKey: repository];
		[d setObject: dict2 forKey: @"manualRepos"];
	}	

	[d synchronize];
	[menuItem setHidden: YES];
	[mc maybeRefresh: self];
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	return nil;
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc repository: (NSString *)repo {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc];
	lock = [[NSLock alloc] init];
	localMod = NO;
	upstreamMod = NO;
	
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
	CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&myPath, 1, NULL);
	CFAbsoluteTime latency = 1.5;
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
		if (![rbd->menuItem isHidden] && (rbd->localMod || rbd->upstreamMod))
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
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	BOOL emulateClock = [def boolForKey: @"emulateClock"];

	if (rbd) {
		if (emulateClock) {
			return rbd->title;
		} else {
			return [rbd->repository lastPathComponent];
		}
	}
	return nil;
}

+ (RepoButtonDelegate *) getModded {
	int i = 0;
	for (i = 0; i < [repos count]; i++) {
		RepoButtonDelegate *rbd = [repos objectAtIndex: i];
		if (![rbd->menuItem isHidden] && (rbd->localMod || rbd->upstreamMod))
			return rbd;
	}
	return nil;
}

+ (BOOL) alreadyHasPath: (NSString *)path {
	int i = 0;
	for (i = 0; i < [repos count]; i++) {
		RepoButtonDelegate *rbd = [repos objectAtIndex: i];
		if ([rbd->repository isEqualToString: path]) {
			[rbd->menuItem setHidden: NO];
			return YES;
		}
	}
	return NO;
}

- (void) commit: (id) menuItem {
}

- (void) clickUpdate: (id) button {
}


@end