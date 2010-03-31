#import "RepoButtonDelegate.h"
#import "RepoHelper.h"
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
	[rbd setDirty: YES];
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc repository: (NSString *)repo {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc];

	repository = repo;
	[repository retain];
	[self setDirty: YES];

	tq = [[TaskQueue alloc] initWithName: repo];
	[tq retain];
	animating = NO;
	interval = 60;
	lock = [[NSLock alloc] init];
	localMod = NO;
	upstreamMod = NO;
	untrackedFiles = NO;
	config = [[NSMutableDictionary alloc] init];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *allRepos = [defaults objectForKey: @"cachedRepos"];
	NSDictionary *thisRepo = [allRepos objectForKey: repo];
	[config setDictionary: thisRepo];
	if ([config objectForKey: @"onofftimes"] == nil)
		[config setObject: [NSMutableArray arrayWithCapacity: 10] forKey: @"onofftimes"];
	
	timer = [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self selector: @selector(checkLocal:) userInfo: nil repeats: NO];
	[timer retain];
	
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

	[self setupUpstream];
	
	return self;
}

- (NSString *)repositoryPath {
	return repository;
}

- (void) setDirty: (BOOL)b {
	if (dirty != b)
		dirty = b;
}

- (void) addMenuItem {
	menuItem = [menu insertItemWithTitle: title action: @selector(beep:) keyEquivalent: @"" atIndex: 1];
	[menuItem retain];
	[menuItem setTarget: self];
	[menuItem setAction: @selector(beep:)];
}

- (void) setupUpstream {
	upstreamName = nil;
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

- (void) openInFinder: (id) sender {
	NSTask *t = [self baseTask: @"/usr/bin/open" fromArguments: [NSArray arrayWithObjects: @".", nil]];
	[tq addTask: t withCallback: nil];
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
	[mc maybeRefresh: self];
	FSEventStreamStop(stream);
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	return nil;
}

- (void) setLocalMod: (BOOL) b {
	if (localMod != b) {
		localMod = b;		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"repoModChange" object: self];
	}
}

- (NSString *)repository {
	return repository;
}

- (void) checkLocal: (NSTimer *) t {
	// NOTE: Doing this on a background thread makes NSTimer confused about where to run when it fires, so it starts missing.
	//       Since we're only re-creating this timer as a result of this timer running, we REALLY do not want to miss.
	dispatch_async(dispatch_get_main_queue(), ^{
		[timer autorelease];
		[timer invalidate];
		timer = [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self selector: @selector(checkLocal:) userInfo: nil repeats: NO];
		[timer retain];
	});
}

- (NSString *)getShort {
	return shortTitle;
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
	
	[self realFire];
	[lock unlock];
}

- (void) realFire {
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