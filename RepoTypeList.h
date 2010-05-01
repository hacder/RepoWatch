#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoInstance.h"

@interface RepoTypeList : NSObject {
	NSArray *typeList;
}

+ (RepoTypeList *) sharedInstance;
- (RepoInstance *) createRepositoryWithPath: (NSString *)path directoryContents: (NSArray *)contents;

@end