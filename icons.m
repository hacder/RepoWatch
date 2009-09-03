#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <stdio.h>
#import "ButtonDelegate.h"
#import "MainController.h"

int main(int argc, char *argv[]) {
	[NSApplication sharedApplication];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *scriptPath = [NSString stringWithFormat: @"%@/scripts", [[NSBundle mainBundle] resourcePath]];
	MainController *mc = [[MainController alloc] initWithDirectory: scriptPath];
	[NSApp run];

	[pool release];
}