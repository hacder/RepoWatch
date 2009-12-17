#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

@interface GitDiffButtonDelegate : RepoButtonDelegate {
	char *git;
	NSString *currentBranch;
}

- (id) initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc gitPath: (char *)gitPath repository: (NSString *)rep window: (NSWindow *)commitWindow textView: (NSTextView *)tv2 button: (NSButton *)butt2 window2: (NSWindow *)window2 textView2: (NSTextView *)tv3;
- (void) updateRemote;

@end