#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ButtonDelegate.h"

@interface PreferencesButtonDelegate : ButtonDelegate <NSWindowDelegate> {
	NSWindow *window;
	NSArray *_plugins;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc plugins: (NSArray *)plugins;


@end