#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"
#import "ButtonDelegate.h"
#import "TaskQueue.h"
#import "Diff.h"

// The general class for Repository types. This needs to be renamed, cleaned up, and made
// more powerful. Eventually I want the ability to easily add new repository types, and this
// class being powerful and general is the main way that will happen.

@interface RepoButtonDelegate : ButtonDelegate <NSTableViewDataSource> {
	NSString *repository;
	NSString *upstreamName;
	NSButton *butt;
	NSTextView *tv;
	NSWindow *window;
	NSTimer *timer;
	NSArray *currentUntracked;
	NSDate *lastRemote;
	Diff *currLocalDiff;
	
	NSString *localDiffSummary; // lines changed, files modified, etc.
	NSAttributedString *localDiff; // the actual diff

	NSWindow *diffCommitWindow;
	NSTextView *diffCommitTV;
	FSEventStreamRef stream;
	BOOL localMod;
	BOOL upstreamMod;
	BOOL untrackedFiles;
	BOOL dirty;
	TaskQueue *tq;
}

// In this section are the functions where the flow has been redesigned. These are the good functions.
// After the first line break are things that might be no longer good.
- initWithTitle: (NSString *)t mainController: (MainController *)mcc repository: (NSString *)repo;
- (void)setupUpstream;
- (void) checkLocal: (NSTimer *) t;
- (NSString *) getShort;
- (void) setLocalMod: (BOOL)b;
- (void) setUpstreamMod: (BOOL)b;
- (void) setDirty: (BOOL)b;
- (NSString *)repositoryPath;
- (NSString *)repository;
- (Diff *)diff;
- (int) getStateValue;

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