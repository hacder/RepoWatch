#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"
#import "ButtonDelegate.h"
#import "TaskQueue.h"

// The general class for Repository types. This needs to be renamed, cleaned up, and made
// more powerful. Eventually I want the ability to easily add new repository types, and this
// class being powerful and general is the main way that will happen.

@interface RepoButtonDelegate : ButtonDelegate <NSTableViewDataSource> {
	NSString *repository;
	NSLock *lock;
	NSString *upstreamName;
	NSButton *butt;
	NSTextView *tv;
	NSWindow *window;
	NSTimeInterval interval;
	NSTimer *timer;
	NSArray *currentUntracked;
	NSDate *lastRemote;
	
	NSWindow *diffCommitWindow;
	NSTextView *diffCommitTV;
	FSEventStreamRef stream;
	BOOL localMod;
	BOOL upstreamMod;
	BOOL untrackedFiles;
	BOOL animating;
	TaskQueue *tq;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc
		repository: (NSString *)repo;
- (void)setupUpstream;
- (void) checkLocal: (NSTimer *) t;
- (NSString *) getShort;

- (void) setAnimating: (BOOL)b;
- (BOOL) hasUntracked;
- (BOOL) hasUpstream;
- (BOOL) hasLocal;

- (void) commit: (id) menuItem;
- (void) pull: (id) menuItem;
- (void) dealWithUntracked: (id) menuItem;

- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv;
- (id)tableView: (NSTableView *)tvv objectValueForTableColumn: (NSTableColumn *)column row: (NSInteger) row;

- (void) clickUpdate: (id) button;
- (NSTask *)taskFromArguments: (NSArray *)args; 
- (NSString *)getDiff;
- (void) openInFinder: (id) sender;
- (void) openInTerminal: (id) sender;
- (NSTask *)baseTask: (NSString *)task fromArguments: (NSArray *)args;
- (NSTask *)taskFromArguments: (NSArray *)args;
- (void) ignore: (id) sender;
- (void) ignoreAll: (id) sender;
- (void) realFire;
- (NSArray *)getUntracked;

+ (NSUInteger)numLocalEdit;
+ (NSUInteger)numRemoteEdit;
+ (NSUInteger)numUpToDate;
+ (BOOL) alreadyHasPath: (NSString *)path;
+ (NSArray *) getRepos;

@end