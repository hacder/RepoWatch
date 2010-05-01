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

- (void) setLogArguments: (NSTask *)t;
- (NSDictionary *) handleSingleLogLineAsArray: (NSArray *)arr;

@end