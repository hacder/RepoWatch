#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <WebKit/WebKit.h>

@interface TwitterTrendView : WebView {
	NSMutableArray *titles;
	NSMutableArray *descriptions;
	BOOL done;
}

- (void) setTrend: (int) index title: (NSString *)ti description: (NSString *)desc;

@end