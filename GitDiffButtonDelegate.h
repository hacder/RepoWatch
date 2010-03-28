#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

// A representation of Git.

@interface GitDiffButtonDelegate : RepoButtonDelegate {
	char *git;
	NSString *currentBranch;
	
	NSString *localDiffSummary; // lines changed, files modified, etc.
	NSAttributedString *localDiff; // the actual diff
}

- (id) initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc gitPath: (char *)gitPath repository: (NSString *)rep;
- (void) updateRemote;
- (NSTask *)taskFromArguments: (NSArray *)args;

@end