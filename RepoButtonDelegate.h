#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"
#import "ButtonDelegate.h"

@interface RepoButtonDelegate : ButtonDelegate {
	NSString *repository;
	NSLock *lock;
	NSButton *butt;
	NSTextView *tv;
	NSWindow *window;
	
	NSImage *redBubble;
	NSImage *yellowBubble;
	NSImage *greenBubble;
	
	NSWindow *diffCommitWindow;
	NSTextView *diffCommitTV;
@public
	BOOL localMod;
	BOOL upstreamMod;
}

- initWithTitle: (NSString *)t menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc repository: (NSString *)repo;
- (void) commit: (id) menuItem;
- (void) clickUpdate: (id) button;
- (NSFileHandle *)pipeForTask: (NSTask *)t;
- (NSString *)stringFromFile: (NSFileHandle *)file;
- (NSTask *)taskFromArguments: (NSArray *)args; 
- (NSArray *)arrayFromResultOfArgs: (NSArray *)args;
- (NSString *)shortenDiff: (NSString *)diff;
- (NSString *)getDiff;
- (void) openInFinder: (id) sender;
- (void) openInTerminal: (id) sender;
- (NSTask *)baseTask: (NSString *)task fromArguments: (NSArray *)args;
- (NSTask *)taskFromArguments: (NSArray *)args;

+ (NSUInteger)numModified;
+ (NSUInteger)numLocalEdit;
+ (NSUInteger)numRemoteEdit;
+ (NSUInteger)numUpToDate;
+ (NSString *)getModText;
+ (RepoButtonDelegate *) getModded;
+ (BOOL) alreadyHasPath: (NSString *)path;

@end