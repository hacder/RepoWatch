#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoInstance.h"

char *concat_path_file(const char *path, const char *filename);
char *find_execable(const char *filename);

@interface BaseRepositoryType : NSObject {
	char *executable;
}

- (BOOL) validRepositoryContents: (NSArray *)contents;
- (RepoInstance *)createRepository: (NSString *)path;
- (BOOL) logFromTodayWithRepository: (RepoInstance *)data;
- (void) updateLogsWithRepository: (RepoInstance *)data;

- (NSArray *) logsWithRepository: (RepoInstance *)data;
- (NSArray *) pendingWithRepository: (RepoInstance *)data;
- (BOOL) hasRemoteWithRepository: (RepoInstance *)data;
- (void) checkRemoteChangesWithRepository: (RepoInstance *)data;
- (BOOL) hasLocalWithRepository: (RepoInstance *)data;
- (void) checkLocalChangesWithRepository: (RepoInstance *)data;

- (void) setLogArguments: (NSTask *)t forRepository: (RepoInstance *)repo;
- (void) setLocalOnlyArguments: (NSTask *)t forRepository: (RepoInstance *)repo;
- (void) setRemoteChangeArguments: (NSTask *)t forRepository: (RepoInstance *)repo;
- (void) setLocalChangeArguments: (NSTask *)t forRepository: (RepoInstance *)repo;
- (NSString *) localDiffArray: (NSArray *)result toStringWithRepository: (RepoInstance *)repo;
- (NSString *) remoteDiffArray: (NSArray *)result toStringWithRepository: (RepoInstance *)repo;

- (NSDictionary *) handleSingleLogLineAsArray: (NSArray *)arr;
- (NSTask *)baseTaskWithRepository: (RepoInstance *)repo;

- (int) removedLinesForRepository: (RepoInstance *)repo;
- (int) addedLinesForRepository: (RepoInstance *)repo;
- (int) changedFilesForRepository: (RepoInstance *)repo;

@end