#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ButtonDelegate.h"

@interface MercurialDiffButtonDelegate : ButtonDelegate {
	char *hg;
	NSString *repository;
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc hgPath: (char *)hgPath repository: (NSString *)rep;

@end