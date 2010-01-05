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
	NSLock *dirtyLock;
	BOOL dirty;
	NSTimeInterval interval;
	NSTimer *timer;
	
	NSWindow *diffCommitWindow;
	NSTextView *diffCommitTV;
	FSEventStreamRef stream;
@public
	BOOL localMod;
	BOOL upstreamMod;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc repository: (NSString *)repo;
- (void) commit: (id) menuItem;
- (void) clickUpdate: (id) button;
- (NSFileHandle *)pipeForTask: (NSTask *)t;
- (NSFileHandle *)errForTask: (NSTask *)t;
- (NSString *)stringFromFile: (NSFileHandle *)file;
- (NSTask *)taskFromArguments: (NSArray *)args; 
- (NSArray *)arrayFromResultOfArgs: (NSArray *)args withName: (NSString *)name;
- (NSString *)shortenDiff: (NSString *)diff;
- (NSString *)getDiff;
- (void) openInFinder: (id) sender;
- (void) openInTerminal: (id) sender;
- (NSTask *)baseTask: (NSString *)task fromArguments: (NSArray *)args;
- (NSTask *)taskFromArguments: (NSArray *)args;
- (void) ignore: (id) sender;
- (void) hideIt;
- (void) setupTimer;
- (void) realFire;
- (NSArray *)getUntracked;

+ (NSUInteger)numLocalEdit;
+ (NSUInteger)numRemoteEdit;
+ (NSUInteger)numUpToDate;
+ (BOOL) alreadyHasPath: (NSString *)path;
+ (NSArray *) getRepos;

@end