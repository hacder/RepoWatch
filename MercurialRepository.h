#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "BaseRepositoryType.h"

@interface MercurialRepository : BaseRepositoryType {
	const char *hg;
}

@end