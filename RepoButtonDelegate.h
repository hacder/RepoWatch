#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"
#import "ButtonDelegate.h"

@interface RepoButtonDelegate : ButtonDelegate {
@public
	BOOL localMod;
	BOOL upstreamMod;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc;

@end