#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// This controls the window for reporting a bug. It's really simple.

@interface MainMenu : NSMenu {
	NSImage *green;
	NSImage *bigGreen;
	
	NSStatusItem *statusItem;
}

- init;

@end