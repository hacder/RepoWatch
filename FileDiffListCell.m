#import "FileDiffListCell.h"
#import "FileDiff.h"
#import <math.h>

@implementation FileDiffListCell

- (id) initTextCell: (NSString *)text {
	self = [super initTextCell: text];
	[self setButtonType: NSSwitchButton];
	[self setEnabled: YES];
	attributes =
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor blackColor],
			NSForegroundColorAttributeName,
			[NSFont systemFontOfSize: 16],
			NSFontAttributeName,
			nil];
	[attributes retain];

	attributes2 = 
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor blackColor],
			NSForegroundColorAttributeName,
			[NSFont systemFontOfSize: 12],
			NSFontAttributeName,
			nil];
	[attributes2 retain];

	attributes4 = 
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSColor grayColor],
			NSForegroundColorAttributeName,
			[NSFont systemFontOfSize: 8],
			NSFontAttributeName,
			nil];
	[attributes4 retain];
	
	return self;
}

- (NSBezierPath *)bezierPathWithRightRoundInRect: (NSRect)aRect radius:(float)radius {
	NSBezierPath* path = [NSBezierPath bezierPath];
	radius = MIN(radius, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
	NSRect rect = NSInsetRect(aRect, radius, radius);
	[path moveToPoint: NSMakePoint(NSMinX(aRect), NSMinY(aRect))];
	[path appendBezierPathWithArcWithCenter: NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius: radius startAngle: 270.0 endAngle: 360.0];
	[path appendBezierPathWithArcWithCenter: NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius: radius startAngle:   0.0 endAngle:  90.0];
	[path lineToPoint: NSMakePoint(NSMinX(aRect), NSMaxY(aRect))];
	[path closePath];
	return path;
}

- (void) setObjectValue: (id <NSCopying, NSObject>) object {
	if ([object isKindOfClass: [FileDiff class]]) {
		[super setObjectValue: [NSNumber numberWithBool: [(FileDiff *)object getIncluded]]];
		[realObjectValue autorelease];
		realObjectValue = object;
		[realObjectValue retain];
	} else {
		[super setObjectValue: object];
	}
}

- (void) drawWithFrame: (NSRect)frame inView: (NSView *)view {
	FileDiff *fd = (FileDiff *)realObjectValue;
	
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

	p.y = frame.origin.y + 25;
	p.x = frame.origin.x + frame.size.width - (s.width + s2.width + 10);
	[[NSColor greenColor] set];
	NSBezierPath *b = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(p.x - 5, frame.origin.y + 25, s.width + s2.width + 15, s.height) xRadius: 5.0 yRadius: 5.0];
	[b fill];
	NSBezierPath *b2 = [self bezierPathWithRightRoundInRect: NSMakeRect(p.x + s.width + 2, frame.origin.y + 25, s2.width + 8, s.height) radius: 5.0];
	[[NSColor redColor] set];
	[b2 fill];
	[[NSColor grayColor] set];
	[b stroke];
	[stringAdded drawAtPoint: p withAttributes: attributes2];
	p.x += s.width + 5;
	[stringRemoved drawAtPoint: p withAttributes: attributes2];
	
	p.x = 5;
	p.y = frame.origin.y + 15;
	
	[super drawWithFrame: frame inView: view];
}

@end