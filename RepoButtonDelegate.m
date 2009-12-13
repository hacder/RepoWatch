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
	[rbd fire];
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc repository: (NSString *)repo {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mc];
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
	CFAbsoluteTime latency = 0.0;
	stream = FSEventStreamCreate(NULL,
		&callbackFunction,
		&fsesc,
		pathsToWatch,
		kFSEventStreamEventIdSinceNow,
		latency,
		kFSEventStreamCreateFlagNone
	);
	
	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);

	return self;
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

- (void) commit: (id) menuItem {
	NSLog(@"Here...");
}

- (void) clickUpdate: (id) button {
	NSLog(@"Here…");
}


@end