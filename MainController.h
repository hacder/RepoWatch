	#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ButtonDelegate;
@class ODeskButtonDelegate;

@interface MainController : NSObject {
	NSStatusItem *statusItem;
	NSMenu *theMenu;
	NSMutableArray *plugins;

	NSMenuItem *normalSeparator;
	NSMenuItem *upstreamSeparator;
	NSMenuItem *localSeparator;
	
	ODeskButtonDelegate *odb;
	NSTimer *timer;

	char *date;
	char *time;
	
	char *git;
	char *hg;
	
	NSTimer *demoTimer;
	BOOL doneRepoSearch;
	BOOL doneStartup;

@public	
	NSLock *lock;

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
- (void) findSupportedSCMS;
- (IBAction) openFile: (id) sender;
- (BOOL) testDirectoryContents: (NSArray *)contents ofPath: (NSString *)path;
- (void) searchPath: (NSString *)path;
- (void) ping;
@end