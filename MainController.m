#import "MainController.h"
#import "ButtonDelegate.h"
#import "LoadButtonDelegate.h"
#import "TwitterTrendingButtonDelegate.h"
#import "PreferencesButtonDelegate.h"
#import "SeparatorButtonDelegate.h"
#import "BitlyStatsButtonDelegate.h"
#import "QuitButtonDelegate.h"
#import "TimeMachineAlertButtonDelegate.h"
#import "TwitFollowerButtonDelegate.h"
#import "WeatherButtonDelegate.h"
#import "GitDiffButtonDelegate.h"
#import "SVNDiffButtonDelegate.h"
#import "MercurialDiffButtonDelegate.h"
#import "ODeskButtonDelegate.h"
#import <Sparkle/Sparkle.h>
#import <dirent.h>
#import <sys/stat.h>

@implementation MainController

- init {
	self = [super init];
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	statusItem = [bar statusItemWithLength: NSVariableStatusItemLength];
	[statusItem retain];
	
	[statusItem setTitle: NSLocalizedString(@"Initializing...", @"")];
	[statusItem setHighlightMode: YES];
	theMenu = [[[NSMenu alloc] initWithTitle: @"Testing"] retain];
	
	[statusItem setMenu: theMenu];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"3", @"trendNumber",
		@"1", @"bitlyEnabled",
		@"2", @"bitlyTimeout",
		@"50", @"bitlyTwitterHistory",
		@"1", @"trendMundaneFilter",
		@"1", @"timeMachineEnabled",
		@"5", @"timeMachineOverdueTime",
		@"1", @"defollowEnabled",
		@"300", @"bitlyDelay",
		@"10", @"loadDelay",
		@"600", @"trendDelay",
		@"600", @"followerDelay",
		@"1", @"loadEnabled",
		@"1", @"twitterEnabled",
		@"1", @"trendingEnabled",
		@"1", @"vcsEnabled",
		@"1", @"weatherEnabled",
		@"0", @"gitTagOnClick",
		nil];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults: dict];	
	plugins = [[NSMutableArray alloc] initWithCapacity: 10];
	
	SUUpdater *su = [SUUpdater sharedUpdater];
	[su checkForUpdatesInBackground];
	
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
	
	p = path = strdup(getenv("PATH"));
	while (p) {
		n = strchr(p, ':');
		if (n)
			*n++ = '\0';
		if (*p != '\0') {
			p = concat_path_file(p, filename);
			struct stat s;
			if (!access(p, X_OK) && !stat(p, &s) && S_ISREG(s.st_mode)) {
				free(path);
				return p;
			}
			free(p);
		}
		p = n;
	}
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

	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: path error: nil];
	if ([contents containsObject: @".git"]) {
		if (git) {
			[plugins addObject: [[GitDiffButtonDelegate alloc] initWithTitle: path menu: theMenu script: nil statusItem: statusItem mainController: self gitPath: git repository: path]];
		}
	} else if ([contents containsObject: @".svn"]) {
		if (svn) {
			[plugins addObject: [[SVNDiffButtonDelegate alloc] initWithTitle: path menu: theMenu script: nil statusItem: statusItem mainController: self svnPath: svn repository: path]];
		}
	} else if ([contents containsObject: @".hg"]) {
		if (hg) {
			[plugins addObject: [[MercurialDiffButtonDelegate alloc] initWithTitle: path menu: theMenu script: nil statusItem: statusItem mainController: self hgPath: hg repository: path]];
		}
	} else {
		int i;
		for (i = 0; i < [contents count]; i++) {
			NSString *s = [[NSString stringWithFormat: @"%@/%@", path, [contents objectAtIndex: i]] retain];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self searchPath: s forGit: git svn: svn hg: hg];
				[s release];
			});
		}
	}
}

- (void) searchAllPathsForGit: (char *)git svn: (char *)svn hg: (char *)hg {
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"vcsEnabled"] == 0)
		return;

	dispatch_async(dispatch_get_main_queue(), ^{
		[self searchPath: [@"~" stringByStandardizingPath] forGit: git svn: svn hg: hg];
	});
}

- (void) findSupportedSCMS {
	char *git = find_execable("git");
	char *svn = find_execable("svn");
	char *hg = find_execable("hg");
	
	NSLog(@"Git: %s Svn: %s Mercurial: %s", git, svn, hg);
	
	// This crawls the file system. It can be quite slow in bad edge cases. Let's put it in the background.
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[self searchAllPathsForGit: git svn: svn hg: hg];
	});
}

- (void)initWithDirectory: (NSString *)dir {
	[self init];
	[plugins addObject: [[LoadButtonDelegate alloc] initWithTitle: @"System Load" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[PreferencesButtonDelegate alloc] initWithTitle: @"Preferences" menu: theMenu script: nil statusItem: statusItem mainController: self plugins: plugins]];
	[plugins addObject: [[TwitterTrendingButtonDelegate alloc] initWithTitle: @"Twitter Trending" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[SeparatorButtonDelegate alloc] initWithTitle: @"Separator" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[QuitButtonDelegate alloc] initWithTitle: @"Quit" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[BitlyStatsButtonDelegate alloc] initWithTitle: @"Bitly" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[TimeMachineAlertButtonDelegate alloc] initWithTitle: @"Time Machine" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[WeatherButtonDelegate alloc] initWithTitle: @"Weather" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[TwitFollowerButtonDelegate alloc] initWithTitle: @"Twitter Follower" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[plugins addObject: [[ODeskButtonDelegate alloc] initWithTitle: @"ODesk" menu: theMenu script: nil statusItem: statusItem mainController: self]];
	[self findSupportedSCMS];
}

- (void)addDir: (NSString *)dir {
	DIR *dire = opendir([dir cStringUsingEncoding: NSUTF8StringEncoding]);
	if (dire == NULL)
		return;
	struct dirent *dent;
	while ((dent = readdir(dire)) != NULL) {
		if (dent->d_name[0] == '.')
			continue;
		NSString *dirPart = [[[NSString alloc] initWithCString: dent->d_name encoding: NSUTF8StringEncoding] autorelease];
		NSString *total = [[[dir stringByAppendingString: @"/"] stringByAppendingString: dirPart] autorelease];
		[[ButtonDelegate alloc] initWithTitle: total menu: theMenu script: total statusItem: statusItem mainController: self];
	}
	closedir(dire);
}

NSInteger sortMenuItems(id item1, id item2, void *context) {
	ButtonDelegate *bd1 = [item1 target];
	ButtonDelegate *bd2 = [item2 target];
	if (bd1 == nil || bd2 == nil)
		return NSOrderedSame;
	if (bd1->priority < bd2->priority)
		return NSOrderedDescending;
	if (bd1->priority > bd2->priority)
		return NSOrderedAscending;
	return NSOrderedSame;
}

- (void) reset {
	NSArray *arr = [theMenu itemArray];
	int i;
	for (i = 0; i < [arr count]; i++) {
		ButtonDelegate *bd = [[arr objectAtIndex: i] target];
		[bd forceRefresh];
	}
	[self rearrange];
}

- (void) maybeRefresh: (ButtonDelegate *)bd {
	NSArray *arr = [theMenu itemArray];
	if ([arr count] == 0)
		return;
	ButtonDelegate *bd2 = [[arr objectAtIndex: 0] target];
	if (bd2 == bd)
		[self rearrange];
}

- (void) rearrange {
	NSArray *arr = [[theMenu itemArray] sortedArrayUsingFunction: sortMenuItems context: NULL];
	int i;
	for (i = 0; i < [arr count]; i++) {
		[theMenu removeItem: [arr objectAtIndex: i]];
		[theMenu insertItem: [arr objectAtIndex: i] atIndex: i];
		[theMenu itemChanged: [arr objectAtIndex: i]];
	}
	for (i = 0; i < [arr count]; i++) {
		if ([[arr objectAtIndex: i] isHidden] == NO) {
			ButtonDelegate *bd2 = [[arr objectAtIndex: i] target];
			NSString *sh = [bd2 shortTitle];
			[statusItem setTitle: sh];
			break;
		}
	}
}

@end