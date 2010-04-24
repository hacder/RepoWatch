#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"
#import "ButtonDelegate.h"
#import "TaskQueue.h"
#import "Diff.h"

@class RepoMenuItem;

// The general class for Repository types. This needs to be renamed, cleaned up, and made
// more powerful. Eventually I want the ability to easily add new repository types, and this
// class being powerful and general is the main way that will happen.

@interface RepoButtonDelegate : ButtonDelegate <NSTableViewDataSource> {
	NSString *repository;
	NSString *upstreamName;
	NSString *upstreamURL;
	NSButton *butt;
	NSTextView *tv;
	NSWindow *window;
	NSTimer *timer;
	NSTimer *upstreamTimer;
	NSArray *currentUntracked;
	NSDate *lastRemote;
	Diff *currLocalDiff;
	RepoMenuItem *menuItem;
	
	NSLock *logLock;
	NSArray *_logs;
	
	NSString *localDiffSummary; // lines changed, files modified, etc.
	NSAttributedString *localDiff; // the actual diff
	NSAttributedString *remoteDiff;
	NSString *commitMessage;

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
- initWithRepositoryName: (NSString *)repo;
- (void) setupUpstream;
- (void) setUntracked: (BOOL) b;
- (void) checkLocal: (NSTimer *) t;
- (void) checkUpstream: (NSTimer *)t;
- (void) setLocalMod: (BOOL)b;
- (void) setUpstreamMod: (BOOL)b;
- (void) setDirty: (BOOL)b;
- (NSString *)repositoryPath;
- (NSString *)repository;
- (Diff *)diff;
- (int) getStateValue;
- (void) setCommitMessage: (NSString *)cm;
- (NSArray *)logs;
- (void) checkUntracked;
- (BOOL) logFromToday;
- (void) setMenuItem: (RepoMenuItem *)mi;
- (RepoMenuItem *)getMenuItem;
- (void) updateLogs;
- (int) logOffset;
- (NSAttributedString *) colorizedDiff;
- (NSAttributedString *) colorizedRemoteDiff;

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
- (void) openInFinder: (id) sender;
- (void) openInTerminal: (id) sender;
- (NSTask *)baseTask: (NSString *)task fromArguments: (NSArray *)args;
- (NSTask *)taskFromArguments: (NSArray *)args;
- (void) ignore: (id) sender;
- (void) ignoreAll: (id) sender;
- (NSArray *)getUntracked;

+ (NSUInteger)numLocalEdit;
+ (NSUInteger)numRemoteEdit;
+ (NSUInteger)numUpToDate;
+ (BOOL) alreadyHasPath: (NSString *)path;
+ (NSArray *) getRepos;

@end