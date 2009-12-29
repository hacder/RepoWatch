#import "MainController.h"
#import "ButtonDelegate.h"
#import "SeparatorButtonDelegate.h"
#import "QuitButtonDelegate.h"
#import "GitDiffButtonDelegate.h"
#import "MercurialDiffButtonDelegate.h"
#import "RepoButtonDelegate.h"
#import <Sparkle/Sparkle.h>
#import <dirent.h>
#import <sys/stat.h>
#import <Carbon/Carbon.h>

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData);

@implementation MainController

BOOL isGoodPath(NSString *path) {
	if ([path hasPrefix: [@"~/Library" stringByStandardizingPath]])
		return NO;
	if ([path hasPrefix: [@"~/Applications" stringByStandardizingPath]])
		return NO;
	if ([path hasPrefix: [@"~/Downloads" stringByStandardizingPath]])
		return NO;
	if ([path hasPrefix: [@"~/Music" stringByStandardizingPath]])
		return NO;
	if ([path hasPrefix: [@"~/Movies" stringByStandardizingPath]])
		return NO;
	if ([path hasPrefix: [@"~/.Trash" stringByStandardizingPath]])
		return NO;
	if ([path hasPrefix: [@"~/.gem" stringByStandardizingPath]])
		return NO;

	NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"ignoredRepos"];
	for (NSString *key in dict) {
		if ([key isEqualToString: path])
			return NO;
	}

	return YES;
}

void mc_callbackFunction(
		ConstFSEventStreamRef streamRef,
		void *clientCallBackInfo,
		size_t numEvents,
		void *eventPaths,
		const FSEventStreamEventFlags eventFlags[],
		const FSEventStreamEventId eventIds[]) {
	
	char **paths = eventPaths;
	int i;
	MainController *mc = (MainController *)clientCallBackInfo;
	for (i = 0; i < numEvents; i++) {
		NSString *s = [NSString stringWithFormat: @"%s", paths[i]];
		if (!isGoodPath(s))
			return;
		break;
	}
	[mc findSupportedSCMS];
}

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
	RepoButtonDelegate *rbd = [RepoButtonDelegate getModded];
	if (rbd)
		[rbd commit: nil];
	return noErr;
}

- init {
	self = [super init];
	date = __DATE__;
	time = __TIME__;
	doneRepoSearch = NO;
	
	git = NULL;
	hg = NULL;
	
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

	lock = [[NSLock alloc] init];
	
	NSDate *expires = [NSDate dateWithNaturalLanguageString: [NSString stringWithFormat: @"%s", date]];
	
	// 30 days from compilation.
	expires = [NSDate dateWithTimeInterval: 3600 * 24 * 30 sinceDate: expires];
	demoTimer = [[NSTimer alloc] initWithFireDate: expires interval: 10 target: self selector: @selector(timeout:) userInfo: nil repeats: NO];
	[demoTimer retain];
	[[NSRunLoop currentRunLoop] addTimer: demoTimer forMode: NSDefaultRunLoopMode];
	
	NSLog(@"Expires at: %@\n", expires);
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	statusItem = [bar statusItemWithLength: NSVariableStatusItemLength];
	[statusItem retain];
	
	[statusItem setTitle: NSLocalizedString(@"RepoWatch", @"")];
	[statusItem setHighlightMode: YES];
	theMenu = [[[NSMenu alloc] initWithTitle: @"Testing"] retain];
	[theMenu setAutoenablesItems: NO];
	
	[statusItem setMenu: theMenu];
	
	plugins = [[NSMutableArray alloc] initWithCapacity: 10];
	
	if ([[NSUserDefaults standardUserDefaults] stringForKey: @"UUID"] == nil) {
		CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
		CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
		NSString *uuidString = [NSString stringWithString:(NSString*)strRef];
		CFRelease(strRef);
		CFRelease(uuidRef);
		
		[[NSUserDefaults standardUserDefaults] setObject: uuidString forKey: @"UUID"];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Drop into Carbon in order to setup global hotkeys.
	EventHotKeyRef myHotKeyRef;
	EventHotKeyID myHotKeyID;
	EventTypeSpec eventType;
	
	eventType.eventClass = kEventClassKeyboard;
	eventType.eventKind = kEventHotKeyPressed;
	InstallApplicationEventHandler(&myHotKeyHandler, 1, &eventType, NULL, NULL);
	myHotKeyID.signature = 'mhk1';
	myHotKeyID.id = 1;
	RegisterEventHotKey(36, cmdKey + optionKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
	
	localSeparator = [NSMenuItem separatorItem];
	[localSeparator setHidden: YES];
	[theMenu addItem: localSeparator];
	upstreamSeparator = [NSMenuItem separatorItem];
	[upstreamSeparator setHidden: YES];
	[theMenu addItem: upstreamSeparator];
	normalSeparator = [NSMenuItem separatorItem];
	[normalSeparator setHidden: YES];
	[theMenu addItem: normalSeparator];
	
	timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: @selector(ping) userInfo: nil repeats: YES];
	
	SUUpdater *updater = [SUUpdater sharedUpdater];
	[updater setFeedURL: [NSURL URLWithString: [NSString stringWithFormat: @"http://www.doomstick.com/mm_update_feed.xml?uuid=%@", [[NSUserDefaults standardUserDefaults] stringForKey: @"UUID"]]]];
	[[SUUpdater sharedUpdater] checkForUpdatesInBackground];

	FSEventStreamRef stream;
	FSEventStreamContext fsesc = {0, self, NULL, NULL, NULL};
	CFStringRef myPath = (CFStringRef)[@"~" stringByExpandingTildeInPath];
	CFArrayRef pathsToWatch = CFArrayCreate(NULL, (const void **)&myPath, 1, NULL);
	CFAbsoluteTime latency = 1.0;
	stream = FSEventStreamCreate(NULL,
		&mc_callbackFunction,
		&fsesc,
		pathsToWatch,
		kFSEventStreamEventIdSinceNow,
		latency,
		kFSEventStreamCreateFlagNone
	);
	
	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
	CFRelease(pathsToWatch);

	[plugins addObject: [[SeparatorButtonDelegate alloc] initWithTitle: @"Separator" menu: theMenu statusItem: statusItem mainController: self]];
	[plugins addObject: [[QuitButtonDelegate alloc] initWithTitle: @"Quit" menu: theMenu statusItem: statusItem mainController: self]];

	[self findSupportedSCMS];

	NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"manualRepos"];
	for (NSString *key in dict) {
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: key error: nil];
		[self testDirectoryContents: contents ofPath: key];
	}
	
    return self;
}

- (IBAction) openFile: (id) sender {
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setCanChooseFiles: NO];
	[op setCanChooseDirectories: YES];
	[op setAllowsMultipleSelection: NO];
	// TODO: Find some way to verify directory before they hit OK.
	if ([op runModal] == NSOKButton) {
		NSString *filename = [op filename];
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: filename error: nil];

		if (![RepoButtonDelegate alreadyHasPath: filename] && ![self testDirectoryContents: contents ofPath: filename]) {
			// TODO: Add alert here.
		} else {
			NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
			NSDictionary *dict = [def dictionaryForKey: @"manualRepos"];
			NSMutableDictionary *dict2;
			if (dict) {
				dict2 = [NSMutableDictionary dictionaryWithDictionary: dict];
			} else {
				dict2 = [NSMutableDictionary dictionaryWithCapacity: 1];
			}
			[dict2 setObject: [[NSDictionary alloc] init] forKey: filename];
			[def setObject: dict2 forKey: @"manualRepos"];
			[def synchronize];
		}
	}
}

char *concat_path_file(const char *path, const char *filename) {
	char *lc;
	if (!path)
		path = "";
	if (path && *path) {
		size_t sz = strlen(path) - 1;
		if ((unsigned char)*(path + sz) == '/')
			lc = (char *)(path + sz);
		else
			lc = NULL;
	} else {
		lc = NULL;
	}
	while (*filename == '/')
		filename++;
	char *tmp;
	asprintf(&tmp, "%s%s%s", path, (lc == NULL ? "/" : ""), filename);
	return tmp;
}

char *find_execable(const char *filename) {
	char *path, *p, *n;
	struct stat s;
	
	p = path = strdup(getenv("PATH"));
	while (p) {
		n = strchr(p, ':');
		if (n)
			*n++ = '\0';
		if (*p != '\0') {
			p = concat_path_file(p, filename);
			if (!access(p, X_OK) && !stat(p, &s) && S_ISREG(s.st_mode)) {
				free(path);
				return p;
			}
			free(p);
		}
		p = n;
	}
	
	// Because the mac is odd sometimes, let's look in a few places that may not
	// be in the path.
	
	n = concat_path_file("/opt/local/bin/", filename);
	if (!access(n, X_OK) && !stat(n, &s) && S_ISREG(s.st_mode))
		return n;
	free(n);

	n = concat_path_file("/sw/bin/", filename);
	if (!access(n, X_OK) && !stat(n, &s) && S_ISREG(s.st_mode))
		return n;
	free(n);

	n = concat_path_file("/usr/local/bin/", filename);
	if (!access(n, X_OK) && !stat(n, &s) && S_ISREG(s.st_mode))
		return n;
	free(n);
	
	n = concat_path_file("/usr/local/", filename);
	p = concat_path_file(n, "/bin/");
	free(n);
	n = concat_path_file(p, filename);
	free(p);
	if (!access(n, X_OK) && !stat(n, &s) && S_ISREG(s.st_mode))
		return n;
	free(n);

	free(path);
	return NULL;
}

- (BOOL) testDirectoryContents: (NSArray *)contents ofPath: (NSString *)path {
	if ([RepoButtonDelegate alreadyHasPath: path])
		return YES;
	if ([contents containsObject: @".git"]) {
		if (git) {
			NSLog(@"Found git repository at %@", path);
			dispatch_async(dispatch_get_main_queue(), ^{
				[plugins addObject: [[GitDiffButtonDelegate alloc] initWithTitle: path
					menu: theMenu statusItem: statusItem mainController: self
					gitPath: git repository: path]];
			});
			return YES;
		}
	} else if ([contents containsObject: @".hg"]) {
		if (hg) {
			NSLog(@"Found mercurial repository at %@", path);
			dispatch_async(dispatch_get_main_queue(), ^{
				[plugins addObject: [[MercurialDiffButtonDelegate alloc] initWithTitle: path
					menu: theMenu statusItem: statusItem mainController: self
					hgPath: hg repository: path]];
			});
			return YES;
		}
	}
	return NO;
}

- (void) searchPath: (NSString *)path {
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity: 10];
	[paths addObject: path];
	
	int high_count = 0;
	
	NSString *curPath;
	while (YES) {
		if ([paths count] == 0)
			break;
		if ([paths count] > high_count)
			high_count = [paths count];
		if ([paths count] > 10000)
			break;
		curPath = [paths objectAtIndex: 0];
		[paths removeObjectAtIndex: 0];
	
		if (!isGoodPath(curPath))
			continue;
		
		NSString *dest = [[NSFileManager defaultManager] destinationOfSymbolicLinkAtPath: curPath error: nil];
		if (!(dest == nil || [dest isEqualToString: curPath]))
			continue;
		
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: curPath error: nil];
		if ([contents count] > 100)
			NSLog(@"Directory count (%@): %d", curPath, [contents count]);
		if (![self testDirectoryContents: contents ofPath: curPath]) {
			int i;
			for (i = 0; i < [contents count]; i++) {
				NSString *s = [NSString stringWithFormat: @"%@/%@", curPath, [contents objectAtIndex: i]];
				[paths addObject: s];
			}
		}
	}
	NSLog(@"High count: %d", high_count);
}

- (void) searchAllPaths {
	[self searchPath: [@"~" stringByStandardizingPath]];
}

- (void) findSupportedSCMS {
	if (![lock tryLock]) {
		NSLog(@"Failing to lock. Bailing");
		return;
	}
	NSLog(@"Searching all paths");
		
	if (!git)
		git = find_execable("git");
	if (!hg)
		hg = find_execable("hg");

	if (!doneRepoSearch) {	
		NSLog(@"Git: %s Mercurial: %s", git, hg);
		doneRepoSearch = YES;
	}
	
	// This crawls the file system. It can be quite slow in bad edge cases. Let's put it in the background.
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[self searchAllPaths];
		dispatch_async(dispatch_get_main_queue(), ^{
			NSLog(@"Done searching");
			[lock unlock];
		});
	});
}

- (void) maybeRefresh: (ButtonDelegate *)bd {
	if ([bd isKindOfClass: [RepoButtonDelegate class]]) {
		RepoButtonDelegate *bd2 = (RepoButtonDelegate *)bd;
		if ([theMenu indexOfItem: [bd2 getMenuItem]] == -1)
			return;
		[theMenu removeItem: [bd2 getMenuItem]];
		NSInteger index = 0;
		
		if (bd2->localMod) {
			index = [theMenu indexOfItem: localSeparator];
		} else if (bd2->upstreamMod) {
			index = [theMenu indexOfItem: upstreamSeparator];
		} else {
			index = [theMenu indexOfItem: normalSeparator];
		}
		[theMenu insertItem: [bd2 getMenuItem] atIndex: index + 1];
	}
}

- (void) timeout: (id) sender {
	[NSApp terminate: self];
}

- (void) ping {
	NSUInteger modded = [RepoButtonDelegate numModified];
	if (modded) {
		// [statusItem setTitle: @""];
		[statusItem setImage: redBubble];
		[statusItem setTitle: [RepoButtonDelegate getModText]];
	} else {
		[statusItem setImage: greenBubble];
		[statusItem setTitle: @""];
		/*
		NSString *clockPlist = [@"~/Library/Preferences/com.apple.menuextra.clock.plist" stringByExpandingTildeInPath];
		NSDictionary *dict = [[[NSDictionary alloc] initWithContentsOfFile: clockPlist] autorelease];
		NSString *format = [dict objectForKey: @"DateFormat"];
		if (!format || [format isEqual: @""])
			format = @"E h:mm a";

		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat: format];
		[dateFormatter autorelease];
		
		NSDate *date2 = [NSDate date];
		[statusItem setTitle: [dateFormatter stringFromDate: date2]];
		*/
	}
}

@end
