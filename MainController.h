#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ButtonDelegate;
@class ODeskButtonDelegate;

@interface MainController : NSObject {
	NSStatusItem *statusItem;
	NSMenu *theMenu;
	NSMutableArray *plugins;
	ButtonDelegate *changedSeparator;
	ButtonDelegate *upstreamSeparator;
	ButtonDelegate *normalSeparator;
	ODeskButtonDelegate *odb;
	NSTimer *timer;
}

- init;
- (void) maybeRefresh: (ButtonDelegate *)bd;
- (void) findSupportedSCMS;

@end