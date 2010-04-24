#import "Scanner.h"
#import "GitRepository.h"
#import "MercurialRepository.h"
#import "RepoButtonDelegate.h"
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

- (void) findRepositories {
	NSDate *start = [NSDate date];
	NSDictionary *dict;
	NSArray *contents;
	
	dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"cachedRepos"];
	if ([dict count]) {
		for (NSString *key in dict) {
			contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: key error: nil];
			[self testDirectoryContents: contents ofPath: [key stringByStandardizingPath]];
		}
	} else {
		[self searchAllPaths];
	}
	NSDate *end = [NSDate date];
	NSLog(@"Time interval: %0.2f", [end timeIntervalSinceDate: start]);	
	[[NSNotificationCenter defaultCenter] postNotificationName: @"scannerDone" object: self];
}

- init {
	self = [super init];
	lock = [[NSLock alloc] init];
	repository_types = [NSArray arrayWithObjects:
		[[GitRepository alloc] init],
		[[MercurialRepository alloc] init],
		nil];
	[repository_types retain];
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[self findRepositories];
	});
	
	return self;
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
		if ([paths count] > 1000) {
			int delay = [paths count] / 100;
			struct timespec ts;
			ts.tv_nsec = delay;
			ts.tv_sec = 0;
			NSLog(@"Delaying for %d.%d seconds to ease off on CPU usage, %d paths to go", 0, delay, [paths count]);
			nanosleep(&ts, NULL);
		}
	}
	NSLog(@"High count: %d", high_count);
}

- (BOOL) testDirectoryContents: (NSArray *)contents ofPath: (NSString *)path {
//	TODO: This functionality NEEDS to be replicated, but that is relatively
//	      difficult with the new class structure
//	if ([RepoButtonDelegate alreadyHasPath: path])
//		return YES;

	int i;
	NSLog(@"There are %d repository types", [repository_types count]);
	for (i = 0; i < [repository_types count]; i++) {
		BaseRepositoryType *brt = [repository_types objectAtIndex: i];
		if ([brt validRepositoryContents: contents]) {
			[self addCachedRepoPath: path];
			RepoButtonDelegate *rbd = [brt createRepository: path];
			[[NSNotificationCenter defaultCenter] postNotificationName: @"repoFound" object: rbd];
			return YES;
		}
	}
	return NO;
}

- (void) addCachedRepoPath: (NSString *)path {
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	NSDictionary *dict = [def dictionaryForKey: @"cachedRepos"];
	if ([dict objectForKey: path] != nil)
		return;
	
	NSLog(@"addCachedRepoPath: %@", path);
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