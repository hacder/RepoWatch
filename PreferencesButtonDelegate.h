#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ButtonDelegate.h"

@interface PreferencesButtonDelegate : ButtonDelegate <NSWindowDelegate> {
	NSWindow *window;
	NSUserDefaults *defaults;
	IBOutlet id _twitterUsername;
	IBOutlet id _twitterPassword;
	NSArray *_plugins;
@public
	NSString *twitterUsername;
	NSString *twitterPassword;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc plugins: (NSArray *)plugins;


@end