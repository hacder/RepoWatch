#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface ThreadCounter : NSObject {
}

+ (void) enterSection;
+ (void) exitSection;
+ (void) debug;

@end