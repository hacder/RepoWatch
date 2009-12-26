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

int mc_ignored = 0;
int mc_passed = 0;

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
		if ([s hasPrefix: [@"~/Library" stringByExpandingTildeInPath]]) {
			mc_ignored++;
			return;
		}
		NSLog(@"Passing %@", s);
		mc_passed++;
		break;
	}
	[mc findSupportedSCMS];
	NSLog(@"Ingored %d, Passed %d (%0.2f%%)", mc_ignored, mc_passed, (mc_ignored * 100.0) / (mc_passed + mc_ignored));
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
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"1", @"timeMachineEnabled",
		@"5", @"timeMachineOverdueTime",
		@"1", @"vcsEnabled",
		@"0", @"gitTagOnClick",
		nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults: dict];	
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
	[localTitle setEnabled: NO];
	localSeparator = [[SeparatorButtonDelegate alloc] initWithTitle: @"Changed" menu: theMenu statusItem: statusItem mainController: self];
	[plugins addObject: localSeparator];
	localSpace = [theMenu insertItemWithTitle: @" " action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[localSpace setEnabled: NO];

	upstreamTitle = [theMenu insertItemWithTitle: @"Upstream Edits" action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[upstreamTitle setEnabled: NO];
	upstreamSeparator = [[SeparatorButtonDelegate alloc] initWithTitle: @"Upstream" menu: theMenu statusItem: statusItem mainController: self];
	[plugins addObject: upstreamSeparator];
	upstreamSpace = [theMenu insertItemWithTitle: @" " action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	
	normalTitle = [theMenu insertItemWithTitle: @"Up To Date" action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[normalTitle setEnabled: NO];
	normalSeparator = [[SeparatorButtonDelegate alloc] initWithTitle: @"Up To Date" menu: theMenu statusItem: statusItem mainController: self];
	[plugins addObject: normalSeparator];
	
	timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: @selector(ping) userInfo: nil repeats: YES];
	
	SUUpdater *updater = [SUUpdater sharedUpdater];
	[updater setFeedURL: [NSURL URLWithString: [NSString stringWithFormat: @"http://www.doomstick.com/mm_update_feed.xml?uuid=%@", [[NSUserDefaults standardUserDefaults] stringForKey: @"UUID"]]]];
	[[SUUpdater sharedUpdater] checkForUpdatesInBackground];

	FSEventStreamRef stream;
	FSEventStreamContext fsesc = {0, self, NULL, NULL, NULL};
	CFStringRef myPath = (CFStringRef)[@"~" stringByExpandingTildeInPath];
	// Leaking this.
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
	
    return self;
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

- (void) searchPath: (NSString *)path forGit: (char *)git hg: (char *)hg {
	// Do not search the library. A LOT of crazy stuff is in there, and it's not a sane place to put repositories.
	if ([path isEqual: [@"~/Library" stringByStandardizingPath]])
		return;
	if ([path isEqual: [@"~/Downloads" stringByStandardizingPath]])
		return;
	if ([path isEqual: [@"~/Music" stringByStandardizingPath]])
		return;
	if ([path isEqual: [@"~/Movies" stringByStandardizingPath]])
		return;
	if ([path isEqual: [@"~/.Trash" stringByStandardizingPath]])
		return;
	
	if ([RepoButtonDelegate alreadyHasPath: path])
		return;
	
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: path error: nil];
	if ([contents containsObject: @".git"]) {
		if (git) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[plugins addObject: [[GitDiffButtonDelegate alloc] initWithTitle: path
					menu: theMenu statusItem: statusItem mainController: self
					gitPath: git repository: path]];
			});
		}
	} else if ([contents containsObject: @".svn"] && ![path isEqual: [@"~" stringByStandardizingPath]]) {
	} else if ([contents containsObject: @".hg"]) {
		if (hg) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[plugins addObject: [[MercurialDiffButtonDelegate alloc] initWithTitle: path
					menu: theMenu statusItem: statusItem mainController: self
					hgPath: hg repository: path]];
			});
		}
	} else {
		int i;
		for (i = 0; i < [contents count]; i++) {
			NSString *s = [[NSString stringWithFormat: @"%@/%@", path, [contents objectAtIndex: i]] retain];
			[self searchPath: s forGit: git hg: hg];
			[s release];
		}
	}
}

- (void) searchAllPathsForGit: (char *)git hg: (char *)hg {
	[self searchPath: [@"~" stringByStandardizingPath] forGit: git hg: hg];
}

- (void) findSupportedSCMS {
	char *git = find_execable("git");
	char *hg = find_execable("hg");

	if (!doneRepoSearch) {	
		NSLog(@"Git: %s Mercurial: %s", git, hg);
		doneRepoSearch = YES;
	}
	
	// This crawls the file system. It can be quite slow in bad edge cases. Let's put it in the background.
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[self searchAllPathsForGit: git hg: hg];
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
		if ([RepoButtonDelegate numLocalEdit] == 0) {
			[localSeparator setHidden: YES];
			[localTitle setHidden: YES];
			[localSpace setHidden: YES];
		} else {
			[localSeparator setHidden: NO];
			[localTitle setHidden: NO];
			[localSpace setHidden: NO];
		}
		if ([RepoButtonDelegate numRemoteEdit] == 0) {
			[upstreamSeparator setHidden: YES];
			[upstreamTitle setHidden: YES];
			[upstreamSpace setHidden: YES];
		} else {
			[upstreamSeparator setHidden: NO];
			[upstreamTitle setHidden: NO];
			[upstreamSpace setHidden: NO];
		}
		if ([RepoButtonDelegate numUpToDate] == 0) {
			[normalSeparator setHidden: YES];
			[normalTitle setHidden: YES];
			[normalSpace setHidden: YES];
		} else {
			[normalSeparator setHidden: NO];
			[normalTitle setHidden: NO];
			[normalSpace setHidden: NO];
		}
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
