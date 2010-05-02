#import "LogMenuView.h"

@implementation LogMenuView

- (void) drawRect: (NSRect) rect {
	CGFloat targetWidth = 150.0;

	if (pending) {
		[[NSColor lightGrayColor] set];
		[NSBezierPath fillRect: rect];
	}
	
	NSSize s = [_date sizeWithAttributes: attributes];
	NSPoint p;
	p.x = targetWidth - s.width;
	p.y = 0;
	
	[_date drawAtPoint: p withAttributes: attributes];
	p.x = 160;
	[_message drawAtPoint: p withAttributes: attributes2];
}

- (void) setPending: (BOOL)p {
	pending = p;
}

- (void) updateWidth {
	NSInteger width = 0;
	NSSize s = [self frame].size;
	width += 165;
	width += [_message sizeWithAttributes: attributes2].width;
	if (s.width < width) {
		s.width = width;
		[self setFrameSize: s];
	}
}

- (void) setDate: (NSString *)date {
	[_date autorelease];
	_date = date;
	[_date retain];
}

- (void) setMessage: (NSString *)message {
	int length = 40;
	
	[_message autorelease];
	if ([message length] >= length) {
		_message = [message substringToIndex: length];
		NSRange r = [_message rangeOfCharacterFromSet: [NSCharacterSet whitespaceCharacterSet] options: NSBackwardsSearch];
		if (r.location != NSNotFound)
			_message = [_message substringToIndex: r.location];
		_message = [NSString stringWithFormat: @"%@...", _message];
	} else {
		_message = message;
	}
	[_message retain];
	
	if (!attributes) {
		attributes = 
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSColor grayColor],
				NSForegroundColorAttributeName,
				[NSFont systemFontOfSize: 12],
				NSFontAttributeName,
				nil];
		[attributes retain];
		attributes2 = 
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSColor blackColor],
				NSForegroundColorAttributeName,
				[NSFont systemFontOfSize: 14],
				NSFontAttributeName,
				nil];
		[attributes2 retain];
	}
	[self updateWidth];
}

@end