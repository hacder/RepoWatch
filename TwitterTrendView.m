#import "TwitterTrendView.h"

@implementation TwitterTrendView

- (id) initWithFrame: (NSRect) rect {
	self = [super initWithFrame: rect];
	return self;
}

- (void) drawRect: (NSRect) rect {
	NSMenuItem *mi = [self enclosingMenuItem];

	if (mi != nil) {
		NSMenu *m = [mi menu];
		[self setFrame: NSMakeRect(rect.origin.x, rect.origin.y, [m size].width, rect.size.height)];
	}

	NSRect bezierRect;
	bezierRect.origin.x = [self frame].origin.x + 20;
	bezierRect.origin.y = [self frame].origin.y;
	bezierRect.size.width = [self frame].size.width - 40;
	bezierRect.size.height = [self frame].size.height;

	[[NSColor grayColor] set];
	NSBezierPath *roundRect = [NSBezierPath bezierPathWithRoundedRect: bezierRect xRadius: 10 yRadius: 10];
	[roundRect fill];
}

@end