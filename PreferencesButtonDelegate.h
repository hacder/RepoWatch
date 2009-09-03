#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ButtonDelegate.h"

@interface PreferencesButtonDelegate : ButtonDelegate <NSWindowDelegate> {
	NSWindow *window;
	NSTextField *_twitterUsername;
	NSSecureTextField *_twitterPassword;
	NSButton *_bitlyEnabled;
	NSUserDefaults *defaults;
@public
	NSString *twitterUsername;
	NSString *twitterPassword;
	BOOL bitlyEnabled;
}

@end