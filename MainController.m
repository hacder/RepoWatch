#import "MainController.h"
#import "ButtonDelegate.h"
#import "SeparatorButtonDelegate.h"
#import "QuitButtonDelegate.h"
#import "GitDiffButtonDelegate.h"
#import "SVNDiffButtonDelegate.h"
#import "MercurialDiffButtonDelegate.h"
#import "ODeskButtonDelegate.h"
#import "TimeMachineAlertButtonDelegate.h"
#import "RepoButtonDelegate.h"
#import <Sparkle/Sparkle.h>
#import <dirent.h>
#import <sys/stat.h>
#import <Carbon/Carbon.h>

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData);

@implementation MainController

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
	
	[plugins addObject: [[TimeMachineAlertButtonDelegate alloc] initWithTitle: @"Time Machine" menu: theMenu statusItem: statusItem mainController: self]];
	odb = [[ODeskButtonDelegate alloc] initWithTitle: @"ODesk" menu: theMenu statusItem: statusItem mainController: self];
	[plugins addObject: odb];
//	[[theMenu insertItemWithTitle: @" " action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]] setEnabled: NO];

	// TODO: Make the headers "active" even with nothing clickable.
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
	
	[self findSupportedSCMS];
	
	timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: @selector(ping) userInfo: nil repeats: YES];

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

- (void) searchPath: (NSString *)path forGit: (char *)git svn: (char *)svn hg: (char *)hg {
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
	
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: path error: nil];
	if ([contents containsObject: @".git"]) {
		if (git) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[plugins addObject: [[GitDiffButtonDelegate alloc] initWithTitle: path
					menu: theMenu statusItem: statusItem mainController: self
					gitPath: git repository: path window: commitWindow textView: tv button: butt]];
			});
		}
	} else if ([contents containsObject: @".svn"] && ![path isEqual: [@"~" stringByStandardizingPath]]) {
		if (svn) {
			NSLog(@"Adding svn to %@", path);
			dispatch_async(dispatch_get_main_queue(), ^{
				[plugins addObject: [[SVNDiffButtonDelegate alloc] initWithTitle: path
					menu: theMenu statusItem: statusItem mainController: self
					svnPath: svn repository: path]];
			});
		}
	} else if ([contents containsObject: @".hg"]) {
		if (hg) {
			NSLog(@"Adding hg to %@", path);
			dispatch_async(dispatch_get_main_queue(), ^{
				[plugins addObject: [[MercurialDiffButtonDelegate alloc] initWithTitle: path
					menu: theMenu statusItem: statusItem mainController: self
					hgPath: hg repository: path window: commitWindow textView: tv button: butt]];
			});
		}
	} else {
		int i;
		for (i = 0; i < [contents count]; i++) {
			NSString *s = [[NSString stringWithFormat: @"%@/%@", path, [contents objectAtIndex: i]] retain];
			[self searchPath: s forGit: git svn: svn hg: hg];
			[s release];
		}
	}
}

- (void) searchAllPathsForGit: (char *)git svn: (char *)svn hg: (char *)hg {
	[self searchPath: [@"~" stringByStandardizingPath] forGit: git svn: svn hg: hg];
}

- (void) findSupportedSCMS {
	char *git = find_execable("git");
	char *svn = find_execable("svn");
	char *hg = find_execable("hg");
	
	NSLog(@"Git: %s Svn: %s Mercurial: %s", git, svn, hg);
	
	// This crawls the file system. It can be quite slow in bad edge cases. Let's put it in the background.
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[self searchAllPathsForGit: git svn: svn hg: hg];
		dispatch_async(dispatch_get_main_queue(), ^{
			[plugins addObject: [[SeparatorButtonDelegate alloc] initWithTitle: @"Separator" menu: theMenu statusItem: statusItem mainController: self]];
			[plugins addObject: [[QuitButtonDelegate alloc] initWithTitle: @"Quit" menu: theMenu statusItem: statusItem mainController: self]];
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

- (void) ping {
	if (odb && odb->running) {
		[statusItem setTitle: odb->title];
	} else {
		NSUInteger modded = [RepoButtonDelegate numModified];
		if (modded) {
			[statusItem setTitle: [RepoButtonDelegate getModText]];
		} else {
			NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:
				[@"~/Library/Preferences/com.apple.menuextra.clock.plist" stringByExpandingTildeInPath]];
			NSString *format = [dict objectForKey: @"DateFormat"];
			if (!format || [format isEqual: @""])
				format = @"E h:mm a";

			NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat: format];
			
			NSDate *date2 = [NSDate date];
			[statusItem setTitle: [dateFormatter stringFromDate: date2]];
		}
	}
}

@end
