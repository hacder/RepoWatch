#import "RepoButtonDelegate.h"
#import "RepoHelper.h"
#import "BaseRepositoryType.h"
#import <dispatch/dispatch.h>
#import <sys/time.h>

@implementation RepoButtonDelegate

static NSMutableArray *repos;
static float fastFrequency = 5.0;
static float slowFrequency = 30.0;

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

- initWithRepositoryName: (NSString *)repo type: (BaseRepositoryType *)type {
	self = [super init];
	repositoryType = type;
	logLock = [[NSLock alloc] init];

	repository = repo;
	[repository retain];
	[self setDirty: YES];

	tq = [[TaskQueue alloc] initWithName: repo];
	[tq retain];
	localMod = NO;
	upstreamMod = NO;
	untrackedFiles = NO;
	
	[self checkLocal: nil];
	
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

- (NSArray *)logs {
	if (_logs == nil)
		[self updateLogs];
	return _logs;
}

- (void) dealWithUntracked: (id) menuItem {
	[currentUntracked release];
	currentUntracked = [self getUntracked];
	[currentUntracked retain];
	[NSApp activateIgnoringOtherApps: YES];
}

- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv {
	return [currentUntracked count];
}

- (id)tableView: (NSTableView *)tvv objectValueForTableColumn: (NSTableColumn *)column row: (NSInteger) row {
	if ([[tvv tableColumns] indexOfObject: column] != 1)
		return @"";
	return [currentUntracked objectAtIndex: row];
}

- (NSTask *)baseTask: (NSString *)task fromArguments: (NSArray *)args {
	NSTask *t = [[NSTask alloc] init];
	[t setLaunchPath: task];
	[t setCurrentDirectoryPath: repository];
	[t setArguments: args];
	[t autorelease];
	
	return t;
}

- (void) setUntracked: (BOOL) b {
	if (untrackedFiles != b) {
		untrackedFiles = b;
		[[NSNotificationCenter defaultCenter] postNotificationName: @"repoStateChange" object: self];
	}
}

- (void) setLocalMod: (BOOL) b {
	if (localMod != b) {
		localMod = b;		
		[[NSNotificationCenter defaultCenter] postNotificationName: @"repoModChange" object: self];
		[[NSNotificationCenter defaultCenter] postNotificationName: @"repoStateChange" object: self];
	}
}

- (void) checkUpstream: (NSTimer *) t {
	dispatch_async(dispatch_get_main_queue(), ^{
		[upstreamTimer autorelease];
		[upstreamTimer invalidate];
		upstreamTimer = [NSTimer scheduledTimerWithTimeInterval: slowFrequency target: self selector: @selector(checkUpstream:) userInfo: nil repeats: NO];
		[upstreamTimer retain];
	});
}

- (void) checkLocal: (NSTimer *) t {
	// NOTE: Doing this on a background thread makes NSTimer confused about where to run when it fires, so it starts missing.
	//       Since we're only re-creating this timer as a result of this timer running, we REALLY do not want to miss.
	dispatch_async(dispatch_get_main_queue(), ^{
		[timer autorelease];
		[timer invalidate];
		timer = [NSTimer scheduledTimerWithTimeInterval: fastFrequency target: self selector: @selector(checkLocal:) userInfo: nil repeats: NO];
		
		// Note: This only works because we are on the time timing frequency as check local. Don't ignore the reason that this
		//       works.
		[self checkUntracked];
		[timer retain];
	});
}

- (void) fire: (NSTimer *)t {
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self fire: nil];
		});
		return;
	}
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

- (BOOL) hasUntracked {
	return untrackedFiles;
}

- (BOOL) hasUpstream {
	return upstreamMod;
}

- (BOOL) hasLocal {
	return localMod;
}

- (void) setCommitMessage: (NSString *)cm {
	[commitMessage release];
	commitMessage = cm;
	[commitMessage retain];
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

- (void) updateLogs {
}

@end