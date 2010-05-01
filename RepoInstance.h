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
- (BOOL) hasUpstream;
- (NSAttributedString *)colorizedDiff;
- (NSAttributedString *)colorizedRemoteDiff;
- (void) setMenuItem: (RepoMenuItem *)item;
- (RepoMenuItem *) menuItem;
- (NSArray *)logs;
- (NSString *)repository;
- (BOOL) logFromToday;
- (NSMutableDictionary *) dict;

@end