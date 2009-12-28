	#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ButtonDelegate;
@class ODeskButtonDelegate;

@interface MainController : NSObject {
	NSStatusItem *statusItem;
	NSMenu *theMenu;
	NSMutableArray *plugins;

	NSMenuItem *normalTitle;
	NSMenuItem *normalSeparator;
	NSMenuItem *normalSpace;

	NSMenuItem *upstreamTitle;
	NSMenuItem *upstreamSeparator;
	NSMenuItem *upstreamSpace;
	
	NSMenuItem *localTitle;
	NSMenuItem *localSeparator;
	NSMenuItem *localSpace;
	
	ODeskButtonDelegate *odb;
	NSTimer *timer;

	char *date;
	char *time;
	
	char *git;
	char *hg;
	
	NSTimer *demoTimer;
	BOOL doneRepoSearch;

	NSLock *lock;
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
- (IBAction) openFile: (id) sender;
- (BOOL) testDirectoryContents: (NSArray *)contents ofPath: (NSString *)path;

@end