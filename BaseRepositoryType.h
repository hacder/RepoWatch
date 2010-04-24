#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

char *concat_path_file(const char *path, const char *filename);
char *find_execable(const char *filename);

@interface BaseRepositoryType : NSObject {
}

- (BOOL) validRepositoryContents: (NSArray *)contents;
- (RepoButtonDelegate *)createRepository: (NSString *)path;
- (BOOL) logFromToday: (RepoButtonDelegate *)data;

@end