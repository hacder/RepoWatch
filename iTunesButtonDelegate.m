#import "iTunesButtonDelegate.h"
#import "iTunes.h"
#import <ScriptingBridge/ScriptingBridge.h>

@implementation iTunesButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc
		statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si
			mainController: mc];
	[self setPriority: 6];
	timeout = 30;
	[self setHidden: YES];
	[self setupTimer];
	return self;
}

- (void) beep: (id) something {
}

- (void) connectionDidFinishLoading: (NSURLConnection *)connection {
}

- (void) fire {
	iTunesApplication *iTunes =
		[SBApplication applicationWithBundleIdentifier: @"com.apple.iZunes"];
	if (!iTunes) {
		[self setHidden: YES];
		NSLog(@"No itunes");
		return;
	}
	
	iTunesEPlS state = [iTunes playerState];
	if ([[iTunes currentTrack] name] == NULL) {
		[self setHidden: YES];
	} else {
		NSString *name = [NSString stringWithFormat: @"%@ (%@)",
				[[iTunes currentTrack] name],
				(state == iTunesEPlSPlaying ? @"Playing" : @"Not Playing")];
		[self setHidden: NO];
		[self setShortTitle: name];
		[self setTitle: name];
	}
}

@end