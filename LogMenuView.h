#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface LogMenuView : NSView {
	NSString *_date;
	NSString *_message;
	NSDictionary *attributes;
	NSDictionary *attributes2;
	BOOL pending;
}

- (void) setDate: (NSString *)date;
- (void) setMessage: (NSString *)message;
- (void) setPending: (BOOL)p;

@end