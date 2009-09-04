#import "iTunesButtonDelegate.h"
#import "iTunes.h"
#import <ScriptingBridge/ScriptingBridge.h>

@implementation iTunesButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	[super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
}

- (void) beep: (id) something {
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection {
}

- (void) fire {
	iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier: @"com.apple.iTunes"];
	if (!iTunes) {
		[self setHidden: YES];
		NSLog(@"No itunes");
		return;
	}
	
	iTunesEPlS state = [iTunes playerState];
	NSString *name = [NSString stringWithFormat: @"%@ (%@)", [[iTunes currentTrack] name], (state == iTunesEPlSPlaying ? @"Playing" : @"Not Playing")];
	if (name) {
		[self setHidden: NO];
		priority = 6;
		[self setShortTitle: name];
		[self setTitle: name];
	} else {
		[self setHidden: YES];
	}
		
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end