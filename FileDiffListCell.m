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
				[NSFont systemFontOfSize: 16],
				NSFontAttributeName,
				nil];

	NSDictionary *attributes3 = 
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSColor greenColor],
				NSForegroundColorAttributeName,
				[NSFont systemFontOfSize: 24],
				NSFontAttributeName,
				nil];

	NSDictionary *attributes2 = 
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSColor grayColor],
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
	p.x = frame.origin.x + 25;
	p.y = frame.origin.y + 5;
	
	[fileName drawAtPoint: p withAttributes: attributes];
	
	p.y += 25;
	[[NSString stringWithFormat: @"+%d", numAdded] drawAtPoint: p withAttributes: attributes2];
	
	p.x += 30;
	[[NSString stringWithFormat: @"-%d", numRemoved] drawAtPoint: p withAttributes: attributes2];
	
	p.x = 5;
	p.y = 15;
	unichar ch = 0x2713;
	[[NSString stringWithCharacters: &ch length: 1] drawAtPoint: p withAttributes: attributes3];
	
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