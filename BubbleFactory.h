#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// This class may well be made obsolete fairly quickly. It returns "bubbles," which
// is what I'm calling the current icon. I want the icons to get more informative,
// prettier, and more flexible. This won't be good enough for that long.

@interface BubbleFactory : NSObject {
}

+ (NSImage *) getRedOfSize: (int)size;
+ (NSImage *) getGreenOfSize: (int)size;
+ (NSImage *) getBlueOfSize: (int)size;
+ (NSImage *) getYellowOfSize: (int)size;

+ (NSImage *)getBubbleOfColor: (NSColor *)highlightColor andSize: (int) size;

@end