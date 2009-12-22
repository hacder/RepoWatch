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

	char *date;
	char *time;
	
	NSTimer *demoTimer;
	BOOL doneRepoSearch;

@public	
	IBOutlet NSWindow *commitWindow;
	IBOutlet NSTextView *tv;
	IBOutlet NSButton *butt;
	IBOutlet NSTextView *diffView;
	
	IBOutlet NSWindow *diffCommitWindow;
	IBOutlet NSButton *undoSingleButton;
	IBOutlet NSButton *changeCommitButton;
	IBOutlet NSButton *goBackToHereButton;
	IBOutlet NSTextView *diffCommitTextView;	
}

- init;
- (void) maybeRefresh: (ButtonDelegate *)bd;
- (void) findSupportedSCMS;

@end