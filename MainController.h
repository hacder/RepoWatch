#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Scanner.h"
#import "MainMenu.h"

@class RepoInstance;

// This is the mega class. Many things need to be moved out of here.

@interface MainController : NSObject {
	char *date;
	char *time;
	
	Scanner *scanner;
	RepoInstance *activeBD;

@public	
	MainMenu *theMenu;

	IBOutlet NSWindow *commitWindow;
	IBOutlet NSTextView *tv;
	IBOutlet NSButton *butt;
	IBOutlet NSTextView *diffView;
	IBOutlet NSSearchField *diffSearch;
	
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
- (IBAction) openFile: (id) sender;
- (void) ping;
- (void) doCommitWindowForRepository: (RepoInstance *)rbd;
+ (MainController *)sharedInstance;

@end