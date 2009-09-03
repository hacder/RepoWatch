#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ButtonDelegate.h"
#import "PreferencesButtonDelegate.h"

@interface BitlyStatsButtonDelegate : ButtonDelegate {
	int last_clicks;
	NSString *curHash;
}

@end