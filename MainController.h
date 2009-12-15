	#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ButtonDelegate;
@class ODeskButtonDelegate;

@interface MainController : NSObject {
	NSStatusItem *statusItem;
	NSMenu *theMenu;
	NSMutableArray *plugins;

	NSMenuItem *normalTitle;
	ButtonDelegate *normalSeparator;
	NSMenuItem *normalSpace;

	NSMenuItem *upstreamTitle;
	ButtonDelegate *upstreamSeparator;
	NSMenuItem *upstreamSpace;
	
	NSMenuItem *localTitle;
	ButtonDelegate *localSeparator;
	NSMenuItem *localSpace;
	
	ODeskButtonDelegate *odb;
	NSTimer *timer;
	
	IBOutlet NSWindow *commitWindow;
	IBOutlet NSTextView *tv;
	IBOutlet NSButton *butt;
	
	char *date;
	char *time;
}

- init;
- (void) maybeRefresh: (ButtonDelegate *)bd;
- (void) findSupportedSCMS;

@end