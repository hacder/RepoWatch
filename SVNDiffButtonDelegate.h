#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

@interface SVNDiffButtonDelegate : RepoButtonDelegate {
	char *svn;
	NSString *repository;
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc svnPath: (char *)svnPath repository: (NSString *)rep;

@end