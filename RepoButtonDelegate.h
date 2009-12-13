#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"
#import "ButtonDelegate.h"

@interface RepoButtonDelegate : ButtonDelegate {
	NSString *repository;
	NSLock *lock;
@public
	BOOL localMod;
	BOOL upstreamMod;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc repository: (NSString *)repo;
- (void) commit: (id) menuItem;
- (void) clickUpdate: (id) button;
+ (NSUInteger)numModified;
+ (NSUInteger)numLocalEdit;
+ (NSUInteger)numRemoteEdit;
+ (NSUInteger)numUpToDate;
+ (NSString *)getModText;
+ (RepoButtonDelegate *) getModded;

@end