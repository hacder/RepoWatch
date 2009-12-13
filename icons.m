#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"

int main(int argc, char *argv[]) {
	[NSApplication sharedApplication];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[MainController alloc] init];
	NSApplicationMain(argc, (const char **)argv);

	[pool release];
	return 0;
}