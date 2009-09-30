#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PreferencesButtonDelegate.h"

@interface ODeskButtonDelegate : ButtonDelegate {
	FILE *f;
	char *date;
	int logged_time;
	int start_time;
	int running;
	int logging;
}

@end