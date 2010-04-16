#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

// Represents Mercurial.

@interface MercurialDiffButtonDelegate : RepoButtonDelegate {
	char *hg;
}

- initWithHG: (char *)hgPath repository: (NSString *)rep;

@end