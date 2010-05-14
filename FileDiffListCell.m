#import "FileDiffListCell.h"
#import "FileDiff.h"
#import <math.h>

@implementation FileDiffListCell

- (void) drawWithFrame: (NSRect)frame inView: (NSView *)view {
	FileDiff *fd = [self objectValue];
	
	NSDictionary *attributes = 
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSColor blackColor],
				NSForegroundColorAttributeName,
				[NSFont systemFontOfSize: 12],
				NSFontAttributeName,
				nil];

	NSString *fileName = [[fd fileName] lastPathComponent];
	int numAdded = [fd numAdded];
	int numRemoved = [fd numRemoved];
	
//	NSGradient *g = [[NSGradient alloc] initWithStartingColor: [NSColor lightGrayColor] endingColor: [NSColor whiteColor]];
//	[g drawInRect: frame angle: 90];

//	[[NSColor lightGrayColor] set];
//	[NSBezierPath fillRect: frame];

	NSPoint p;
	p.x = frame.origin.x;
	p.y = frame.origin.y;
	
	[fileName drawAtPoint: p withAttributes: attributes];
	
	p.y += 15;
	[[NSString stringWithFormat: @"+%d", numAdded] drawAtPoint: p withAttributes: attributes];
	
	p.x += 30;
	[[NSString stringWithFormat: @"-%d", numRemoved] drawAtPoint: p withAttributes: attributes];
	
//	NSSize s = [_date sizeWithAttributes: attributes];
//	NSPoint p;
//	p.x = targetWidth - s.width;
//	p.y = 0;
//	
//	[_date drawAtPoint: p withAttributes: attributes];
//	p.x = 130;
//	[_message drawAtPoint: p withAttributes: attributes2];
}

@end