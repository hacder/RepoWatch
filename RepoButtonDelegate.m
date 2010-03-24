#import "RepoButtonDelegate.h"
#import "ThreadCounter.h"
#import "RepoHelper.h"
#import <dispatch/dispatch.h>
#import <sys/time.h>

@implementation RepoButtonDelegate

static NSMutableArray *repos;
static dispatch_queue_t sync_queue;
static NSMutableArray *lastCommands;

+ (void) setupQueue {
	sync_queue = dispatch_queue_create("com.doomstick.RepoWatch.repository_tasks", NULL);
}

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
		NSLog(@"Setting %@ to dirty", rbd->shortTitle);
		rbd->dirty = YES;
	}
	[rbd->dirtyLock unlock];
}

- (void) dealWithUntracked: (id) menuItem {
	[currentUntracked release];
	currentUntracked = [self getUntracked];
	[currentUntracked retain];
	[mc->untrackedTable setDataSource: self];
	[mc->untrackedWindow center];
	[mc->untrackedIgnoreAll setAction: @selector(ignoreAll:)];
	[mc->untrackedIgnoreAll setTarget: self];
	[mc->untrackedAddAll setAction: @selector(addAll:)];
	[mc->untrackedAddAll setTarget: self];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->untrackedWindow makeKeyAndOrderFront: NSApp];	
}

- (void) ignoreAll: (id) sender {
}

- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv {
	return [currentUntracked count];
}

- (id)tableView: (NSTableView *)tvv objectValueForTableColumn: (NSTableColumn *)column row: (NSInteger) row {
	if ([[tvv tableColumns] indexOfObject: column] != 1)
		return @"";
	return [currentUntracked objectAtIndex: row];
}

- (NSArray *)getUntracked {
	return nil;
}

- (NSArray *)arrayFromResultOfArgs: (NSArray *)args withName: (NSString *)name {
	NSTask *t = [self taskFromArguments: args];
	NSFileHandle *file = [RepoHelper pipeForTask: t];
	NSFileHandle *err = [RepoHelper errForTask: t];

	@try {
		[t launch];
		
		NSString *string = [RepoHelper stringFromFile: file];
		NSArray *result = [string componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\0"]];
		[t waitUntilExit];
		if ([t terminationStatus] != 0) {
			NSMutableString *command = [NSMutableString stringWithCapacity: 20];
			[command appendFormat: @"%@: %@", [t currentDirectoryPath], [t launchPath]];
			int i;
			for (i = 0; i < [args count]; i++) {
				[command appendFormat: @" %@", [args objectAtIndex: i]];
			}
			NSString *errStr = [RepoHelper stringFromFile: err];
			NSLog(@"%@, task status: %d error: %@ full command: %@", name, [t terminationStatus], errStr, command);
			return nil;
		}
		[err closeFile];
		[file closeFile];

		if ([[result objectAtIndex: [result count] - 1] isEqualToString: @""]) {
			NSMutableArray *result2 = [NSMutableArray arrayWithArray: result];
			[result2 removeObjectAtIndex: [result2 count] - 1];
			return result2;
		}
		
		return result;
	} @catch (NSException *e) {
		NSLog(@"Got exception: %@", e);
	}
	return nil;
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
	[t autorelease];
	
	NSString *taskString = [NSString stringWithFormat: @"%@ %@", repository, task];
	int i;
	for (i = 0; i < [args count]; i++) {
		taskString = [NSString stringWithFormat: @"%@ %@", taskString, [args objectAtIndex: i]];
	}
	[lastCommands addObject: taskString];
	[singleRepoLastCommands addObject: taskString];

	NSLog(@"Task string: %@", taskString);
	NSLog(@"I know about %d commands", [lastCommands count]);
	NSLog(@"For just %@ I know about %d commands", repository, [singleRepoLastCommands count]);
	
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

- (void) setAnimating: (BOOL)b {
	animating = b;
	[mc setAnimatingFor: self to: b];
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc repository: (NSString *)repo {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc];
	singleRepoLastCommands = [NSMutableArray arrayWithCapacity: 10];
	[singleRepoLastCommands retain];
	animating = NO;
	dirtyLock = [[NSLock alloc] init];
	[dirtyLock lock];
	dirty = NO;
	[dirtyLock unlock];
	interval = 60;
	lock = [[NSLock alloc] init];
	localMod = NO;
	upstreamMod = NO;
	untrackedFiles = NO;
	
	timer = nil;
	[self setupTimer];
	
	repository = repo;
	[repository retain];

	if (!repos) {
		repos = [NSMutableArray arrayWithCapacity: 10];
		[repos retain];
	}
	[repos addObject: self];

	if (!lastCommands) {
		lastCommands = [NSMutableArray arrayWithCapacity: 10];
		[lastCommands retain];
	}

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

- (NSString *)getShort {
	return shortTitle;
}

- (void) setupTimer {
	float minTime = 1.0 * ([RepoButtonDelegate numLocalEdit] + [RepoButtonDelegate numRemoteEdit] + 1);
	float maxTime = 60.0;
	
	if (minTime < 5.0)
		minTime = 5.0;
	
	if (localMod || upstreamMod)
		interval = interval / 2.0;
	else
		interval += 1.0;
	
	if (!localMod)
		minTime *= 5;
	
	if (interval < minTime)
		interval = minTime;
	else if (interval > maxTime)
		interval = maxTime;

	[timer invalidate];
	[timer release];
	timer = [NSTimer scheduledTimerWithTimeInterval: interval target: self selector: @selector(fire:) userInfo: nil repeats: NO];
	[timer retain];
}

- (NSString *)getDiff {
	NSArray *arr = [NSArray arrayWithObjects: @"diff", nil];
	NSTask *t = [self taskFromArguments: arr];
	NSFileHandle *file = [RepoHelper pipeForTask: t];
	[t launch];
	NSString *result = [RepoHelper stringFromFile: file];
	[file closeFile];
	return result;
}

- (void) fire: (NSTimer *)t {
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self fire: nil];
		});
		return;
	}
	if (![lock tryLock]) {
		NSLog(@"Trying to run while already locked: %@", repository);
		return;
	}
	
	[self setAnimating: YES];
	NSLog(@"%@", repository);
	dispatch_async(sync_queue, ^{
		[ThreadCounter enterSection];
		[self realFire];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setupTimer];
			[self setAnimating: NO];
			[lock unlock];
		});
		[ThreadCounter exitSection];
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

- (BOOL) hasUntracked {
	return untrackedFiles;
}

- (BOOL) hasUpstream {
	return upstreamMod;
}

- (BOOL) hasLocal {
	return localMod;
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

- (void) pull: (id) menuItem {
}

- (void) clickUpdate: (id) button {
}


@end