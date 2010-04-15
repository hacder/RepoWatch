#import "BubbleFactory.h"

@implementation BubbleFactory

+ (NSImage *)getBubbleOfColor: (NSColor *)highlightColor andSize: (int) size {
	float lineWidth = 2 * (size / 15.0);
	
	NSColor *color = [highlightColor blendedColorWithFraction: 0.75 ofColor: [NSColor whiteColor]];
	NSImage *ret = [[NSImage alloc] initWithSize: NSMakeSize(size, size)];
	[ret autorelease];
	[ret lockFocus];
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(lineWidth / 2, lineWidth / 2, size - lineWidth, size - lineWidth)];
	NSGradient *aGradient = [[[NSGradient alloc] initWithStartingColor: color endingColor: highlightColor] autorelease];
	[aGradient drawInBezierPath: path relativeCenterPosition: NSMakePoint(0.2, 0.2)];
	[path setLineWidth: lineWidth];
	
	[[color blendedColorWithFraction: 0.75 ofColor: [NSColor blackColor]] set];
	[path stroke];
	[ret unlockFocus];
	return ret;
}

+ (NSImage *) getRedOfSize: (int)size {
	return [BubbleFactory getBubbleOfColor: [NSColor colorWithCalibratedRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0] andSize: size];
}

+ (NSImage *) getYellowOfSize: (int)size {
	return  [BubbleFactory getBubbleOfColor: [NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 0.0 alpha: 1.0] andSize: size];
}

+ (NSImage *) getGreenOfSize: (int)size {
	return [BubbleFactory getBubbleOfColor: [NSColor colorWithCalibratedRed: 0.0 green: 1.0 blue: 0.0 alpha: 0.1] andSize: size];
}

+ (NSImage *) getBlueOfSize: (int)size {
	return [BubbleFactory getBubbleOfColor: [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0] andSize: size];
}

@end