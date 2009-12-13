#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "MainController.h"

int main(int argc, char *argv[]) {
	[NSApplication sharedApplication];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *scriptPath = [NSString stringWithFormat: @"%@/scripts", [[NSBundle mainBundle] resourcePath]];
	[[MainController alloc] initWithDirectory: scriptPath];
	NSApplicationMain(argc, (const char **)argv);

	[pool release];
	return 0;
}