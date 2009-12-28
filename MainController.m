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
	
	localTitle = [theMenu insertItemWithTitle: @"Local Edits" action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[localTitle setHidden: YES];
	[localTitle setEnabled: NO];
	localSeparator = [[SeparatorButtonDelegate alloc] initWithTitle: @"Changed" menu: theMenu statusItem: statusItem mainController: self];
	[localSeparator setHidden: YES];
	[plugins addObject: localSeparator];
	localSpace = [theMenu insertItemWithTitle: @" " action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[localSpace setEnabled: NO];
	[localSpace setHidden: YES];

	upstreamTitle = [theMenu insertItemWithTitle: @"Upstream Edits" action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[upstreamTitle setEnabled: NO];
	[upstreamTitle setHidden: YES];
	upstreamSeparator = [[SeparatorButtonDelegate alloc] initWithTitle: @"Upstream" menu: theMenu statusItem: statusItem mainController: self];
	[upstreamSeparator setHidden: YES];
	[plugins addObject: upstreamSeparator];
	upstreamSpace = [theMenu insertItemWithTitle: @" " action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[upstreamSpace setHidden: YES];
	
	normalTitle = [theMenu insertItemWithTitle: @"Up To Date" action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[normalTitle setHidden: YES];
	[normalTitle setEnabled: NO];
	normalSeparator = [[SeparatorButtonDelegate alloc] initWithTitle: @"Up To Date" menu: theMenu statusItem: statusItem mainController: self];
	[normalSeparator setHidden: YES];
	[plugins addObject: normalSeparator];
	
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
		if (![self testDirectoryContents: contents ofPath: filename]) {
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
		return NO;
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
	if (!isGoodPath(path))
		return;	
	NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path error: nil];
	if ([fileAttributes objectForKey: @"NSFileType"] == NSFileTypeSymbolicLink)
		return;

	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: path error: nil];
	if (![self testDirectoryContents: contents ofPath: path]) {
		int i;
		for (i = 0; i < [contents count]; i++) {
			NSString *s = [[NSString stringWithFormat: @"%@/%@", path, [contents objectAtIndex: i]] retain];
			NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
			[self searchPath: s];
			[innerPool release];
			[s release];
		}
	}
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
			index = [theMenu indexOfItem: [localSeparator getMenuItem]];
		} else if (bd2->upstreamMod) {
			index = [theMenu indexOfItem: [upstreamSeparator getMenuItem]];
		} else {
			index = [theMenu indexOfItem: [normalSeparator getMenuItem]];
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
		[statusItem setTitle: [RepoButtonDelegate getModText]];
	} else {
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
	}
}

@end
