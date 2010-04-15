#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"
#import "Diff.h"

// A representation of Git.

@interface GitDiffButtonDelegate : RepoButtonDelegate {
	char *git;
	NSString *currentBranch;
	NSLock *logLock;
	NSArray *_logs;
}

- (id) initWithTitle: (NSString *)s gitPath: (char *)gitPath repository: (NSString *)rep;
- (NSTask *)taskFromArguments: (NSArray *)args;

@end