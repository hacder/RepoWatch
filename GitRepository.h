#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "BaseRepositoryType.h"

@interface GitRepository : BaseRepositoryType {
	const char *git;
}

@end