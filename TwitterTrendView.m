#import "TwitterTrendView.h"

@implementation TwitterTrendView

- (id) initWithFrame: (NSRect) rect {
	self = [super initWithFrame: rect];
	[self setFrameLoadDelegate: self];
	titles = [[NSMutableArray arrayWithObjects: @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", nil] retain];
	descriptions = [[NSMutableArray arrayWithObjects: @"", @"", @"", @"", @"", @"", @"", @"", @"", @"", nil] retain];
	done = NO;
	return self;
}

- (void) setTrend: (int) index title: (NSString *)ti description: (NSString *)desc {
	[titles replaceObjectAtIndex: (index - 1) withObject: ti];
	[descriptions replaceObjectAtIndex: (index - 1) withObject: desc];
	if (done) {
		WebFrame *wf = [self mainFrame];
		DOMHTMLDocument *dom = (DOMHTMLDocument *)[wf DOMDocument];
		DOMHTMLElement *el = (DOMHTMLElement *)[dom getElementById: [NSString stringWithFormat: @"tt%d", index]];
		[el setInnerHTML: ti];
		el = (DOMHTMLElement *)[dom getElementById: [NSString stringWithFormat: @"ttd%d", index]];
		[el setInnerHTML: desc];
	}
}

- (void) setMainFrameURL: (NSString *)url {
	[super setMainFrameURL: url];
	NSLog(@"Setting url!");
}

- (void) webView: (id)wv didStartProvisionalLoadForFrame: (id)f {
	NSLog(@"webView:%@ didStartProvisionalLoadForFrame: %@", wv, f);
}

- (void) webView: (id)wv willCloseFrame: (id)f {
	NSLog(@"webView:%@ willCloseFrame: %@", wv, f);
}

- (void) webView: (id)wv didCommitLoadForFrame: (id)f {
	NSLog(@"webView:%@ didCommitLoadForFrame:%@", wv, f);
}

- (void) webView: (id)wv didReceiveTitle: (NSString *)t forFrame: (id)f {
	NSLog(@"webView:%@ didReceiveTitle:%@ forFrame:%@", wv, t, f);
}

- (void) webView: (id)wv didFinishLoadForFrame: (id)f {
	done = YES;
	int i;
	for (i = 1; i <= 10; i++) {
		NSLog(@"Setting %d", i);
		[self setTrend: i title: [titles objectAtIndex: (i - 1)] description: [descriptions objectAtIndex: (i - 1)]];
	}
}

- (void) webView: (id)wv didFailProvisionalLoadWithError: (id)err forFrame: (id)f {
	NSLog(@"webView:%@ didFailProvisionalLoadWithError:%@ forFrame:%@", wv, err, f);
}

- (void) webView: (id)wv didFailLoadWithError: (id)err forFrame: (id)f {
	NSLog(@"webView:%@ didFailLoadWithError:%@ forFrame:%@", wv, err, f);
}


@end