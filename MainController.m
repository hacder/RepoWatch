#import "MainController.h"
#import "ButtonDelegate.h"
#import "PreferencesButtonDelegate.h"
#import "SeparatorButtonDelegate.h"
#import "QuitButtonDelegate.h"
#import "GitDiffButtonDelegate.h"
#import "SVNDiffButtonDelegate.h"
#import "MercurialDiffButtonDelegate.h"
#import "ODeskButtonDelegate.h"
#import "TimeMachineAlertButtonDelegate.h"
#import <Sparkle/Sparkle.h>
#import <dirent.h>
#import <sys/stat.h>

@implementation MainController

- init {
	self = [super init];
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	statusItem = [bar statusItemWithLength: NSVariableStatusItemLength];
	[statusItem retain];
	
	[statusItem setTitle: NSLocalizedString(@"RepoWatch", @"")];
	[statusItem setHighlightMode: YES];
	theMenu = [[[NSMenu alloc] initWithTitle: @"Testing"] retain];
	
	[statusItem setMenu: theMenu];
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"1", @"timeMachineEnabled",
		@"5", @"timeMachineOverdueTime",
		@"1", @"vcsEnabled",
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
			NSLog(@"Adding git to %@", path);
			dispatch_async(dispatch_get_main_queue(), ^{
				[plugins addObject: [[GitDiffButtonDelegate alloc] initWithTitle: path
					menu: theMenu statusItem: statusItem mainController: self
					gitPath: git repository: path]];
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
			[self searchPath: s forGit: git svn: svn hg: hg];
			[s release];
		}
	}
}

- (void) searchAllPathsForGit: (char *)git svn: (char *)svn hg: (char *)hg {
	if ([[NSUserDefaults standardUserDefaults] integerForKey: @"vcsEnabled"] == 0)
		return;

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
			[plugins addObject: [[PreferencesButtonDelegate alloc] initWithTitle: @"Preferences" menu: theMenu statusItem: statusItem mainController: self plugins: plugins]];
			[plugins addObject: [[QuitButtonDelegate alloc] initWithTitle: @"Quit" menu: theMenu statusItem: statusItem mainController: self]];
		});
	});
}

- (void)initWithDirectory: (NSString *)dir {
	[self init];
	[plugins addObject: [[TimeMachineAlertButtonDelegate alloc] initWithTitle: @"Time Machine" menu: theMenu statusItem: statusItem mainController: self]];
	[plugins addObject: [[ODeskButtonDelegate alloc] initWithTitle: @"ODesk" menu: theMenu statusItem: statusItem mainController: self]];
	[theMenu insertItemWithTitle: @" " action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];

	[theMenu insertItemWithTitle: @"Up To Date" action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[plugins addObject: [[SeparatorButtonDelegate alloc] initWithTitle: @"Separator" menu: theMenu statusItem: statusItem mainController: self]];
	[theMenu insertItemWithTitle: @" " action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];

	[theMenu insertItemWithTitle: @"Local Edits" action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[plugins addObject: [[SeparatorButtonDelegate alloc] initWithTitle: @"Separator" menu: theMenu statusItem: statusItem mainController: self]];
	[theMenu insertItemWithTitle: @" " action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	
	[theMenu insertItemWithTitle: @"Upstream Edits" action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	[plugins addObject: [[SeparatorButtonDelegate alloc] initWithTitle: @"Separator" menu: theMenu statusItem: statusItem mainController: self]];
	[theMenu insertItemWithTitle: @" " action: nil keyEquivalent: @"" atIndex: [theMenu numberOfItems]];
	
	[self findSupportedSCMS];
}

NSInteger sortMenuItems(id item1, id item2, void *context) {
	ButtonDelegate *bd1 = [item1 target];
	ButtonDelegate *bd2 = [item2 target];
	if (bd1 == nil || bd2 == nil)
		return NSOrderedSame;
//	if (bd1->priority < bd2->priority)
//		return NSOrderedDescending;
//	if (bd1->priority > bd2->priority)
//		return NSOrderedAscending;
	return NSOrderedSame;
}

- (void) maybeRefresh: (ButtonDelegate *)bd {
	NSArray *arr = [theMenu itemArray];
	if ([arr count] == 0)
		return;
}

@end
