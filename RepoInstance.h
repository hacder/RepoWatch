#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "RepoMenuItem.h"

@class BaseRepositoryType;

@interface RepoInstance : NSObject {
	BaseRepositoryType *_repoType;
	NSString *_shortTitle;
	NSString *_path;
	NSMutableDictionary *_data;
}

- (id) initWithRepoType: (BaseRepositoryType *)type shortTitle: (NSString *)title path: (NSString *)path;
- (NSString *)shortTitle;
- (BOOL) hasLocal;
- (BOOL) hasUntracked;
- (BOOL) hasRemote;
- (NSAttributedString *)colorizedDiff;
- (NSAttributedString *)colorizedRemoteDiff;
- (void) setMenuItem: (RepoMenuItem *)item;
- (RepoMenuItem *) menuItem;
- (NSString *)repository;
- (BOOL) logFromToday;
- (NSMutableDictionary *) dict;
- (NSArray *)logs;
- (NSArray *)pending;
- (void)tick;
- (void)checkRemoteChanges;
- (void)checkLocalChanges;

@end