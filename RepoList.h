#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface RepoList : NSObject {
	NSMutableArray *list;
}

+ (RepoList *) sharedInstance;
- (NSInteger) numberRecentRepositories;
- (NSArray *) recentRepositories;
- (NSArray *) allRepositories;

@end