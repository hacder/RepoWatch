#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Scanner.h"
#import "QuitButtonDelegate.h"

// This is the mega class. Many things need to be moved out of here.

@class ButtonDelegate;

@interface MainController : NSObject {
	NSStatusItem *statusItem;
	NSMenu *theMenu;

	NSMenuItem *normalSeparator;
	NSMenuItem *upstreamSeparator;
	NSMenuItem *localSeparator;
	
	char *date;
	char *time;
	
	Scanner *scanner;
	QuitButtonDelegate *quit;
	ButtonDelegate *activeBD;

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
	
	IBOutlet NSWindow *untrackedWindow;
	IBOutlet NSTableView *untrackedTable;
	IBOutlet NSButton *untrackedButton;
	IBOutlet NSButton *untrackedAddAll;
	IBOutlet NSButton *untrackedIgnoreAll;
	IBOutlet NSTableView *fileList;
}

- init;
- (void) maybeRefresh: (ButtonDelegate *)bd;
- (IBAction) openFile: (id) sender;
- (void) ping;

@end