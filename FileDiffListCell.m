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

	NSDictionary *attributes4 = 
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSColor grayColor],
				NSForegroundColorAttributeName,
				[NSFont systemFontOfSize: 8],
				NSFontAttributeName,
				nil];

	NSString *fileName = [[fd fileName] lastPathComponent];
	int numAdded = [fd numAdded];
	int numRemoved = [fd numRemoved];
	
	NSString *fullName = [fd fileName];
	NSString *baseRepo = [[fd repo] repository];
	fullName = [fullName substringFromIndex: [baseRepo length] + 1];
	
	NSPoint p;
	p.x = frame.origin.x + 5;
	p.y = frame.origin.y;
	
	[fileName drawAtPoint: p withAttributes: attributes];
	p.y += 15;
	
	if (![fullName isEqualToString: fileName])
		[fullName drawAtPoint: p withAttributes: attributes4];
	

	NSString *stringAdded = [NSString stringWithFormat: @"%d", numAdded];
	NSSize s = [stringAdded sizeWithAttributes: attributes2];
	NSString *stringRemoved = [NSString stringWithFormat: @"%d", numRemoved];
	NSSize s2 = [stringRemoved sizeWithAttributes: attributes2];

	p.y = 30;
	p.x = frame.origin.x + frame.size.width - (s.width + s2.width + 10);
	[[NSColor greenColor] set];
	NSBezierPath *b = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(p.x - 5, 30, s.width + s2.width + 15, s.height) xRadius: 5.0 yRadius: 5.0];
	[b fill];
	[[NSColor blackColor] set];
	[stringAdded drawAtPoint: p withAttributes: attributes2];
	p.x += s.width + 5;
	[stringRemoved drawAtPoint: p withAttributes: attributes2];
	
	p.x = 5;
	p.y = frame.origin.y + 15;
	unichar ch = 0x2713;
	[[NSString stringWithCharacters: &ch length: 1] drawAtPoint: p withAttributes: attributes3];
}

@end