#import "iTunesButtonDelegate.h"
#import "iTunes.h"
#import <ScriptingBridge/ScriptingBridge.h>

@implementation iTunesButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	[self setPriority: 6];
	return self;
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
	if ([[iTunes currentTrack] name] == NULL) {
		[self setHidden: YES];
	} else {
		NSString *name = [NSString stringWithFormat: @"%@ (%@)", [[iTunes currentTrack] name], (state == iTunesEPlSPlaying ? @"Playing" : @"Not Playing")];
		[self setHidden: NO];
		[self setShortTitle: name];
		[self setTitle: name];
	}
		
}

- (NSString *)runScriptWithArgument: (NSString *)arg {
}

@end