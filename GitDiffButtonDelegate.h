#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

@interface GitDiffButtonDelegate : RepoButtonDelegate {
	char *git;
	NSString *currentBranch;
	NSLock *lock;
}

- (id) initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc gitPath: (char *)gitPath repository: (NSString *)rep;
- (void) commit: (id) menuItem;

@end