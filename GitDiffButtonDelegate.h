#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"
#import "Diff.h"

// A representation of Git.

@interface GitDiffButtonDelegate : RepoButtonDelegate {
	char *git;
	NSString *currentBranch;
	NSString *remoteDiffStat;
}

- (id) initWithGit: (char *)gitPath repository: (NSString *)rep;
- (NSTask *)taskFromArguments: (NSArray *)args;

@end