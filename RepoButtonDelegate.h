#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"
#import "ButtonDelegate.h"

@interface RepoButtonDelegate : ButtonDelegate <NSTableViewDataSource> {
	NSString *repository;
	NSLock *lock;
	NSButton *butt;
	NSTextView *tv;
	NSWindow *window;
	NSLock *dirtyLock;
	BOOL dirty;
	NSTimeInterval interval;
	NSTimer *timer;
	NSArray *currentUntracked;
	
	NSWindow *diffCommitWindow;
	NSTextView *diffCommitTV;
	FSEventStreamRef stream;
	BOOL localMod;
	BOOL upstreamMod;
	BOOL untrackedFiles;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc repository: (NSString *)repo;
- (NSString *) getShort;
- (BOOL) hasUntracked;
- (BOOL) hasUpstream;
- (BOOL) hasLocal;
- (void) commit: (id) menuItem;
- (void) pull: (id) menuItem;
- (void) dealWithUntracked: (id) menuItem;
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv;
- (id)tableView: (NSTableView *)tvv objectValueForTableColumn: (NSTableColumn *)column row: (NSInteger) row;
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
- (void) ignoreAll: (id) sender;
- (void) hideIt;
- (void) setupTimer;
- (void) realFire;
- (NSArray *)getUntracked;

+ (NSUInteger)numLocalEdit;
+ (NSUInteger)numRemoteEdit;
+ (NSUInteger)numUpToDate;
+ (BOOL) alreadyHasPath: (NSString *)path;
+ (NSArray *) getRepos;
+ (void) setupQueue;

@end