#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

// Represents Mercurial.

@interface MercurialDiffButtonDelegate : RepoButtonDelegate {
	char *hg;
}

- initWithTitle: (NSString *)s hgPath: (char *)hgPath repository: (NSString *)rep;

@end