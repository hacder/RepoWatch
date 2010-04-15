#import "BubbleFactory.h"

@implementation BubbleFactory

+ (NSImage *)getBubbleOfColor: (NSColor *)highlightColor andSize: (int) size {
	if (size > 15)
		size = 15;
		
	float lineWidth = 2 * (size / 15.0);
	
	int x_offset = (15 - size) / 2.0;
	int y_offset = (15 - size) / 2.0;
	
	NSColor *color = [highlightColor blendedColorWithFraction: 0.75 ofColor: [NSColor whiteColor]];
	NSImage *ret = [[NSImage alloc] initWithSize: NSMakeSize(15, 15)];
	[ret autorelease];
	[ret lockFocus];
	float x = x_offset + (lineWidth / 2);
	float y = y_offset + (lineWidth / 2);
	float w = size - lineWidth;
	float h = w;
	
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(x, y, w, h)];
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