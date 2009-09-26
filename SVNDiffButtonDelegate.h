#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ButtonDelegate.h"

@interface SVNDiffButtonDelegate : ButtonDelegate {
	char *svn;
	NSString *repository;
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc svnPath: (char *)svnPath repository: (NSString *)rep;

@end