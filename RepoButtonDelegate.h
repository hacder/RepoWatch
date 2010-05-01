#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"
#import "ButtonDelegate.h"
#import "TaskQueue.h"
#import "Diff.h"

@class RepoMenuItem;
@class BaseRepositoryType;

// The general class for Repository types. This needs to be renamed, cleaned up, and made
// more powerful. Eventually I want the ability to easily add new repository types, and this
// class being powerful and general is the main way that will happen.

@interface RepoButtonDelegate : ButtonDelegate <NSTableViewDataSource> {
	NSString *repository;
	NSString *upstreamName;
	NSString *upstreamURL;
	NSTimer *timer;
	NSTimer *upstreamTimer;
	NSArray *currentUntracked;
	Diff *currLocalDiff;
	RepoMenuItem *menuItem;
	BaseRepositoryType *repositoryType;
	
	NSLock *logLock;
	NSArray *_logs;
	
	NSString *localDiffSummary; // lines changed, files modified, etc.
	NSAttributedString *localDiff; // the actual diff
	NSAttributedString *remoteDiff;
	NSString *commitMessage;
	
	FSEventStreamRef stream;
	BOOL localMod;
	BOOL upstreamMod;
	BOOL untrackedFiles;
	BOOL dirty;
	TaskQueue *tq;
}

- initWithRepositoryName: (NSString *)repo type: (BaseRepositoryType *)type;
- (void) setupUpstream;
- (void) setUntracked: (BOOL) b;
- (void) checkLocal: (NSTimer *) t;
- (void) checkUpstream: (NSTimer *)t;
- (void) setLocalMod: (BOOL)b;
- (void) setDirty: (BOOL)b;
- (NSString *)repositoryPath;
- (NSString *)repository;
- (Diff *)diff;
- (int) getStateValue;
- (void) setCommitMessage: (NSString *)cm;
- (NSArray *)logs;
- (void) checkUntracked;
- (void) setMenuItem: (RepoMenuItem *)mi;
- (RepoMenuItem *)getMenuItem;
- (int) logOffset;
- (NSAttributedString *) colorizedDiff;
- (NSAttributedString *) colorizedRemoteDiff;
- (BOOL) hasUntracked;
- (BOOL) hasUpstream;
- (BOOL) hasLocal;
- (void) commit: (id) menuItem;
- (void) dealWithUntracked: (id) menuItem;
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tv;
- (id)tableView: (NSTableView *)tvv objectValueForTableColumn: (NSTableColumn *)column row: (NSInteger) row;
- (NSTask *)baseTask: (NSString *)task fromArguments: (NSArray *)args;
- (NSArray *)getUntracked;
+ (BOOL) alreadyHasPath: (NSString *)path;
- (void) updateLogs;

@end