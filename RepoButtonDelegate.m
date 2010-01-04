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
	[rbd->dirtyLock lock];
	if (!rbd->dirty) {
		[GrowlApplicationBridge notifyWithTitle: @"Dirty Repository" description: rbd->repository notificationName: @"testing" iconData: nil priority: 1.0 isSticky: NO clickContext: nil];

		NSLog(@"Setting %@ to dirty", rbd->shortTitle);
		rbd->dirty = YES;
	}
	[rbd->dirtyLock unlock];
}

- (NSString *)shortenDiff: (NSString *)diff {
	NSArray *parts = [diff componentsSeparatedByString: @", "];
	if ([parts count] == 3) {
		int num_files = [[parts objectAtIndex: 0] intValue];
		int num_plus = [[parts objectAtIndex: 1] intValue];
		int num_minus = [[parts objectAtIndex: 2] intValue];
		
		if (!num_plus && !num_minus)
			return nil;
		NSString *ret = [NSString stringWithFormat: @"%d files, +%d -%d", num_files, num_plus, num_minus];
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

- (NSArray *)arrayFromResultOfArgs: (NSArray *)args withName: (NSString *)name {
	NSTask *t = [[self taskFromArguments: args] autorelease];
	NSFileHandle *file = [self pipeForTask: t];
	NSFileHandle *err = [self errForTask: t];

	@try {
		[t launch];
		
		NSString *string = [self stringFromFile: file];
		NSArray *result = [string componentsSeparatedByString: @"\n"];
		[t waitUntilExit];
		if ([t terminationStatus] != 0) {
			NSLog(@"%@, task status: %d error: %@", name, [t terminationStatus], [self stringFromFile: err]);
		}
		[err closeFile];
		[file closeFile];
		return result;
	} @catch (NSException *e) {
		NSLog(@"Got exception: %@", e);
	}
	return nil;
}

- (NSFileHandle *)pipeForTask: (NSTask *)t {
	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	return file;
}

- (NSFileHandle *)errForTask: (NSTask *)t {
	NSPipe *pipe = [NSPipe pipe];
	[t setStandardError: pipe];
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
	FSEventStreamStop(stream);
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	return nil;
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc repository: (NSString *)repo {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc];
	dirtyLock = [[NSLock alloc] init];
	[dirtyLock lock];
	dirty = NO;
	[dirtyLock unlock];
	interval = 60;
	lock = [[NSLock alloc] init];
	localMod = NO;
	upstreamMod = NO;
	
	timer = nil;
	[self setupTimer];
	
	repository = repo;
	[repository retain];

	if (!repos) {
		repos = [NSMutableArray arrayWithCapacity: 10];
		[repos retain];
	}
	[repos addObject: self];

	FSEventStreamContext fsesc = {0, self, NULL, NULL, NULL};
	CFStringRef myPath = (CFStringRef)repository;
	CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&myPath, 1, NULL);

	NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
	float lat = [d floatForKey: @"fseventDelay"];

	CFAbsoluteTime latency = lat ? lat : 1.5;
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

- (void) setupTimer {
//	NSLog(@"Setting up timer for %f on %@", interval, shortTitle);
	if (localMod || upstreamMod) {
		interval = interval / 2.0;
	} else {
		interval += 1.0;
	}
	
	if (interval < 2.0) {
		interval = 2.0;
	} else if (interval > 60.0) {
		interval = 60.0;
	}
	[timer release];
	NSLog(@"Timer for %@ set to %f", shortTitle, interval);
	timer = [NSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(fire:) userInfo: nil repeats: NO];
	[timer retain];
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

- (void) fire: (NSTimer *)t {
	NSLog(@"Calling fire on %@", repository);
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		NSLog(@"Called %@ from wrong queue, switching", repository);
		dispatch_async(dispatch_get_main_queue(), ^{
			[self fire: nil];
		});
		return;
	}
	if (![lock tryLock])
		return;
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSLog(@"Calling real fire for %@ in background", repository);
		[self realFire];
		dispatch_async(dispatch_get_main_queue(), ^{
			NSLog(@"Setting up timer for %@", repository);
			[self setupTimer];
			[lock unlock];
		});
	});
}

- (void) realFire {
}

- (void) hideIt {
	[menuItem setHidden: YES];
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

+ (NSArray *)getRepos {
	return repos;
}

- (void) commit: (id) menuItem {
}

- (void) clickUpdate: (id) button {
}


@end