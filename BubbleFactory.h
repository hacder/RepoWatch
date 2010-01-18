#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface BubbleFactory : NSObject {
}

+ (NSImage *) getRedOfSize: (int)size;
+ (NSImage *) getGreenOfSize: (int)size;
+ (NSImage *) getBlueOfSize: (int)size;
+ (NSImage *) getYellowOfSize: (int)size;

+ (NSImage *)getBubbleOfColor: (NSColor *)highlightColor andSize: (int) size;

@end