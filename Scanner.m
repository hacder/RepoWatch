#import "GitDiffButtonDelegate.h"
#import "RepoButtonDelegate.h"
#import "Scanner.h"
#import "MercurialDiffButtonDelegate.h"
#import <dirent.h>
#import <sys/stat.h>

@implementation Scanner

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
	if ([path hasPrefix: [@"/Applications" stringByStandardizingPath]])
		return NO;
	if ([path rangeOfString: @"/."].location != NSNotFound)
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
	Scanner *mc = (Scanner *)clientCallBackInfo;
	if (![mc->lock tryLock]) {
		NSLog(@"Failing to lock. Bailing.");
		return;
	}
	int i;
	for (i = 0; i < numEvents; i++) {
		NSString *s = [NSString stringWithFormat: @"%s", paths[i]];
		if (!isGoodPath(s))
			continue;

		[mc searchPath: s];
	}
	[mc->lock unlock];
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

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc];
	done = NO;
	lock = [[NSLock alloc] init];	

	NSLog(@"Path is: %s", getenv("PATH"));

	git = find_execable("git");
	hg = find_execable("hg");
	NSLog(@"Git: %s Mercurial: %s", git, hg);
	
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: [NSString stringWithFormat: @"%s", git]];
	[task setArguments: [NSArray arrayWithObjects: @"--version", nil]];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];	
	[task launch];
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[[NSString alloc] initWithData: data
			encoding: NSUTF8StringEncoding] autorelease];
	NSLog(@"Git version: %d", [string intValue]);

/* Take away auto-scan for now.
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
*/
	
	NSDictionary *dict;
	dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"cachedRepos"];
	for (NSString *key in dict) {
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: key error: nil];
		[self testDirectoryContents: contents ofPath: [key stringByStandardizingPath]];
	}

	dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"manualRepos"];
	for (NSString *key in dict) {
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: key error: nil];
		[self testDirectoryContents: contents ofPath: [key stringByStandardizingPath]];
	}
	done = YES;

	return self;
}

- (BOOL) isDone {
	return done;
}

- (void) beep: (id) something {
	[self findSupportedSCMS];
}

- (void) findSupportedSCMS {
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self findSupportedSCMS];
		});
		return;
	}
	if (![lock tryLock]) {
		NSLog(@"Failing to lock. Bailing");
		return;
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

- (void) searchAllPaths {
	[self searchPath: [@"~" stringByStandardizingPath]];
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
		if ([paths count] > 100000)
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
		if (![self testDirectoryContents: contents ofPath: [curPath stringByStandardizingPath]]) {
			int i;
			for (i = 0; i < [contents count]; i++) {
				NSString *s = [[NSString stringWithFormat: @"%@/%@", curPath, [contents objectAtIndex: i]] stringByStandardizingPath];
				[paths addObject: s];
			}
		}
	}
	NSLog(@"High count: %d", high_count);
}

- (BOOL) testDirectoryContents: (NSArray *)contents ofPath: (NSString *)path {
	if ([RepoButtonDelegate alreadyHasPath: path])
		return YES;
	if ([contents containsObject: @".git"]) {
		if (git) {
			[self addCachedRepoPath: path];
			[[GitDiffButtonDelegate alloc] initWithTitle: path
				menu: menu statusItem: statusItem mainController: mc
				gitPath: git repository: path];
			return YES;
		}
	} else if ([contents containsObject: @".hg"]) {
		if (hg) {
			[self addCachedRepoPath: path];
			[[MercurialDiffButtonDelegate alloc] initWithTitle: path
				menu: menu statusItem: statusItem mainController: mc
				hgPath: hg repository: path];
			return YES;
		}
	}
	return NO;
}

- (void) addCachedRepoPath: (NSString *)path {
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [def dictionaryForKey: @"cachedRepos"];
	NSMutableDictionary *dict2;
	if (dict) {
		dict2 = [NSMutableDictionary dictionaryWithDictionary: dict];
	} else {
		dict2 = [NSMutableDictionary dictionaryWithCapacity: 1];
	}
	[dict2 setObject: [[NSDictionary alloc] init] forKey: path];
	[def setObject: dict2 forKey: @"cachedRepos"];
	[def synchronize];
}

- (void) openFile: (NSString *)filename withContents: (NSArray *)contents {
	if (![RepoButtonDelegate alreadyHasPath: filename] && ![self testDirectoryContents: contents ofPath: [filename stringByStandardizingPath]]) {
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

@end