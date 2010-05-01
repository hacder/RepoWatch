#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface RepoList : NSObject {
	NSMutableArray *list;
}

+ (RepoList *) sharedInstance;

@end