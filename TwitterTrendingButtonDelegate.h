#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ButtonDelegate.h"
#import "PreferencesButtonDelegate.h"
#import "TwitterTrendView.h"

@interface TwitterTrendingButtonDelegate : ButtonDelegate {
	TwitterTrendView *tv;
}

@end