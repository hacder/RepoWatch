#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Scanner.h"
#import "QuitButtonDelegate.h"

@class ButtonDelegate;
@class ODeskButtonDelegate;

@interface MainController : NSObject {
	NSStatusItem *statusItem;
	NSMenu *theMenu;

	NSMenuItem *normalSeparator;
	NSMenuItem *upstreamSeparator;
	NSMenuItem *localSeparator;
	
	NSTimer *timer;

	char *date;
	char *time;
	
	NSTimer *demoTimer;
	Scanner *scanner;
	QuitButtonDelegate *quit;
	
@public	
	NSImage *redBubble;
	NSImage *yellowBubble;
	NSImage *greenBubble;
	
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
- (IBAction) openFile: (id) sender;
- (void) ping;
@end