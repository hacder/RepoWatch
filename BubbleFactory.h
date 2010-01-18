#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface BubbleFactory : NSObject {
}

+ (NSImage *) getRed;
+ (NSImage *) getGreen;
+ (NSImage *) getBlue;
+ (NSImage *) getYellow;

@end