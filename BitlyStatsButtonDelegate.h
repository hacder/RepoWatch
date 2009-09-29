#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "TwitterBaseButtonDelegate.h"
#import "PreferencesButtonDelegate.h"

@interface BitlyStatsButtonDelegate : TwitterBaseButtonDelegate {
	int last_clicks;
	NSString *curHash;
	NSCalendar *greg;
}

@end