#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// This controls the window for reporting a bug. It's really simple.

@interface BugController : NSObject <NSWindowDelegate> {
	IBOutlet NSTextView *bugText;
	IBOutlet NSButton *button;
	IBOutlet NSWindow *window;
	IBOutlet NSArrayController *ac;
}

- (IBAction) submitBug: (id) sender;  

@end