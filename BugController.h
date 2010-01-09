#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface BugController : NSObject {
	IBOutlet NSTextView *bugText;
	IBOutlet NSButton *button;
	IBOutlet NSWindow *window;
}

- (IBAction) submitBug: (id) sender;  

@end