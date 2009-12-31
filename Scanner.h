#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ButtonDelegate.h"

@interface Scanner : ButtonDelegate {
	NSLock *lock;
	char *git;
	char *hg;	
	NSMutableArray *plugins;
	BOOL done;
}

- (void) findSupportedSCMS;
- (void) searchAllPaths;
- (void) searchPath: (NSString *)path;
- (BOOL) testDirectoryContents: (NSArray *)contents ofPath: (NSString *)path;
- (void) addCachedRepoPath: (NSString *)path;
- (void) openFile: (NSString *)filename withContents: (NSArray *)contents;
- (BOOL) isDone;

@end