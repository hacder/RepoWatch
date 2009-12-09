#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"
#import "ButtonDelegate.h"

@interface RepoButtonDelegate : ButtonDelegate {
	NSString *repository;
@public
	BOOL localMod;
	BOOL upstreamMod;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc repository: (NSString *)repo;
+ (NSUInteger)numModified;
+ (NSString *)getModText;

@end