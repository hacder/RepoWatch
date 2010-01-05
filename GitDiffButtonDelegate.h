#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

@interface GitDiffButtonDelegate : RepoButtonDelegate <NSTableViewDataSource> {
	char *git;
	NSString *currentBranch;
}

- (id) initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc gitPath: (char *)gitPath repository: (NSString *)rep;
- (void) updateRemote;
- (NSTask *)taskFromArguments: (NSArray *)args;

@end