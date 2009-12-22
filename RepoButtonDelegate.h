#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"
#import "ButtonDelegate.h"

@interface RepoButtonDelegate : ButtonDelegate {
	NSString *repository;
	NSLock *lock;
	NSButton *butt;
	NSTextView *tv;
	NSWindow *window;
	MainController *mc;
	
	NSWindow *diffCommitWindow;
	NSTextView *diffCommitTV;
@public
	BOOL localMod;
	BOOL upstreamMod;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc repository: (NSString *)repo;
- (void) commit: (id) menuItem;
- (void) clickUpdate: (id) button;
- (NSFileHandle *)pipeForTask: (NSTask *)t;
- (NSString *)stringFromFile: (NSFileHandle *)file;
- (NSTask *)taskFromArguments: (NSArray *)args;
- (NSArray *)arrayFromResultOfArgs: (NSArray *)args;

+ (NSUInteger)numModified;
+ (NSUInteger)numLocalEdit;
+ (NSUInteger)numRemoteEdit;
+ (NSUInteger)numUpToDate;
+ (NSString *)getModText;
+ (RepoButtonDelegate *) getModded;
+ (BOOL) alreadyHasPath: (NSString *)path;

@end