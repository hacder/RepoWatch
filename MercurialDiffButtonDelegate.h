#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

// Represents Mercurial.

@interface MercurialDiffButtonDelegate : RepoButtonDelegate {
	const char *hg;
}

- initWithHG: (const char *)hgPath repository: (NSString *)rep;

@end