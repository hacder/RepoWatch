#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

@interface MercurialDiffButtonDelegate : RepoButtonDelegate {
	char *hg;
}

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc hgPath: (char *)hgPath repository: (NSString *)rep window: (NSWindow *)commitWindow textView: (NSTextView *)tv2;

@end