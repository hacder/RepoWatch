#import "MainController.h"
#import "ButtonDelegate.h"
#import "GitDiffButtonDelegate.h"
#import "MercurialDiffButtonDelegate.h"
#import "RepoButtonDelegate.h"
#import "Scanner.h"
#import "RepoHelper.h"
#import <Sparkle/Sparkle.h>
#import <Carbon/Carbon.h>
#import <AppKit/NSApplication.h>

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData);

static MainController *shared;

@implementation MainController

+ (MainController *)sharedInstance {
	return shared;
}

- (void) commitFromMenu: (id) menu {
	[self doCommitWindowForRepository: [menu representedObject]];
}

// This is what is called when you press our global hot key: Command + Option + Enter. A lot of
// logic is in here because the goal of this app is simplicity. There is ONE global hot key that
// does the most logical thing at any given moment.
OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
	MainController *mc = (MainController *)userData;
	
	int t = [mc->theMenu numberOfItems];
	int i;
	
	// Loop over all of the menu items. We'll break out quickly if there is something to do. We're sorted
	// by priority already, so in the real world, the most important action is the top menu item.
	for (i = 0; i < t; i++) {
		NSMenuItem *mi = [mc->theMenu itemAtIndex: i];
		
		// The exception to the above rule, and the reason why we have to loop at all, is when
		// an item is hidden. Unfortunately, currently, when you remove an item I'm lazy and just
		// hide it. It's still officially in the menu. We can't look at that.
		if (![mi isHidden]) {
			
			// Another exception to the rule is the hidden separator items. Or any other special Button
			// Delegate instances I may put into the menu in the future. We want to make sure that
			// we are dealing with some kind of repository.
			if (![[mi target] isKindOfClass: [RepoButtonDelegate class]])
				continue;

			RepoButtonDelegate *rbd = (RepoButtonDelegate *)[mi target];
			
			// Untracked files are the main concern when they exist. We can't deal with local changes
			// really until we are sure if these untracked files should count as local edits.
			if ([rbd hasUntracked]) {
				[rbd dealWithUntracked: nil];
				return noErr;
			}

			// Local changes should be commited locally before you pull in upstream updates.
			if ([rbd hasLocal]) {
				[mc doCommitWindowForRepository: rbd];
				return noErr;
			}
			
			// Upstream updates are the least important thing, though you should still pull
			// as frequently as you can.
			if ([rbd hasUpstream]) {
				[rbd pull: nil];
				return noErr;
			}
			
			// Alright, let's let the user use the task switcher.
			[mc->tc showWindow];
			
			return noErr;
		}
	}
	return noErr;
}

- (void) doCommitWindowForRepository: (RepoButtonDelegate *)rbd {
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self doCommitWindowForRepository: rbd];
		});
		return;
	}
	
	[commitWindow center];
	[commitWindow setTitle: [rbd shortTitle]];
	[commitWindow makeKeyAndOrderFront: self];
	[[diffView textStorage] setAttributedString: [RepoHelper colorizedDiffFromArray: [[rbd getDiff] componentsSeparatedByString: @"\n"]]];
	[NSApp activateIgnoringOtherApps: YES];
	[tv setString: @""];
	[commitWindow makeFirstResponder: tv];
	[rbd setCommitMessage: [tv string]];
	[butt setEnabled: YES];
	[butt setTarget: rbd];
	[butt setAction: @selector(commit:)];
	
	Diff *d = [rbd diff];
	[fileList setDataSource: d];
}

- (void) scannerDone: (id)ignored {
	[self ping];
}

- (void) commitStart: (id) ignored {
	[butt setEnabled: NO];
}

- (void) commitDone: (id)ignored {
	[commitWindow close];
}

- init {
	self = [super init];
	shared = self;
	
	// The active button delegate. This is the Button Delegate that has control of the main menu
	// text and image.
	activeBD = nil;
	
	theMenu = [[[MainMenu alloc] init] retain];
	
	// Set up a universal ID. This is used a lot on the backend to collate things into individual
	// users. It's not personally identifying (at least, not without you helping me out a bit),
	// but is good enough for stats.
	if ([[NSUserDefaults standardUserDefaults] stringForKey: @"UUID"] == nil) {
		CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
		CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
		NSString *uuidString = [NSString stringWithString:(NSString*)strRef];
		CFRelease(strRef);
		CFRelease(uuidRef);
		
		[[NSUserDefaults standardUserDefaults] setObject: uuidString forKey: @"UUID"];
	}
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Drop into Carbon in order to setup global hotkeys.
	EventHotKeyRef myHotKeyRef;
	EventHotKeyID myHotKeyID;
	EventTypeSpec eventType;
	
	eventType.eventClass = kEventClassKeyboard;
	eventType.eventKind = kEventHotKeyPressed;
	InstallApplicationEventHandler(&myHotKeyHandler, 1, &eventType, (void *)self, NULL);
	myHotKeyID.signature = 'mhk1';
	myHotKeyID.id = 1;
	RegisterEventHotKey(36, cmdKey + optionKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
	
	// Set up Sparkle. Unfortunately I haven't started using this yet, and I'm not sure how to make it do the
	// updates correctly, but it's here already.
	SUUpdater *updater = [SUUpdater sharedUpdater];
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *build = [infoDict objectForKey: @"CFBundleVersion"];
	
	NSURL *appcastURL = [NSURL URLWithString: [NSString stringWithFormat: @"http://www.doomstick.com/shine/appcast.php?id=7&uuid=%@&version=%@&osv=%f",
			[[NSUserDefaults standardUserDefaults] stringForKey: @"UUID"],
			[build stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding],
			NSAppKitVersionNumber]];
		NSLog(@"Using url: %@", appcastURL);
	[updater setFeedURL: appcastURL];
	[[SUUpdater sharedUpdater] checkForUpdatesInBackground];

	scanner = [[Scanner alloc] init];

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(scannerDone:) name: @"scannerDone" object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(commitDone:) name: @"commitDone" object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(commitStart:) name: @"commitDone" object: nil];
    return self;
}

// The user has asked to open a specific file. Actually, this can easily be a directory,
// in which case we scan just like we would initially. This allows the user to have 
// repositories in places that aren't under Home.
- (IBAction) openFile: (id) sender {
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setCanChooseFiles: NO];
	[op setCanChooseDirectories: YES];
	[op setAllowsMultipleSelection: NO];

	// TODO: Find some way to verify directory before they hit OK. This may be difficult since we want to be
	// able to scan. MAYBE there is a toggle for scan, or a different menu item. That way the simple, most
	// common case of not scanning could maybe verify.
	if ([op runModal] == NSOKButton) {
		NSString *filename = [op filename];
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: filename error: nil];

		// If they had previously ignored a repository, this will undo the ignore.
		NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
		NSDictionary *dict = [def dictionaryForKey: @"ignoredRepos"];
		NSMutableDictionary *dict2;
		if (dict) {
			dict2 = [NSMutableDictionary dictionaryWithDictionary: dict];
			[dict2 removeObjectForKey: filename];
			[def setObject: dict2 forKey: @"ignoredRepos"];
		}

		// Scan this directory with the same scanner object that's available via the menu.
		[scanner openFile: filename withContents: contents];
	}
}

- (void) timeout: (id) sender {
	[NSApp terminate: self];
}

#define PI 3.14159

// This code might want to be put into a more general helper class. It's only currently used here, but that could change.
// Note that this rotates "backwards", ie, counter clockwise.
+ (NSImage*)rotateImage: (NSImage*)orig byDegrees: (float)deg {
	NSImage *rotated = [[NSImage alloc] initWithSize:[orig size]];
	NSRect rect;
	rect.size = orig.size;
	rect.origin = NSZeroPoint;
	[rotated lockFocus];
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy: [orig size].width * 0.5 yBy: [orig size].height * 0.5];
	[transform rotateByDegrees:deg];
	[transform translateXBy: [orig size].width * -0.5 yBy: [orig size].height * -0.5];
	[transform concat];
	[orig drawAtPoint: NSZeroPoint fromRect: rect operation:NSCompositeCopy fraction:1.0];
	[rotated unlockFocus];
	[orig autorelease];
	return [rotated autorelease];
}

// Stupid little method that does little except call other, more important methods. This method is called periodically
// and any time that the system knows that things have changed. It is the main method for updating global state.
- (void) ping {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (![theMenu numberOfItems])
			return;
		NSMenuItem *mi = [theMenu itemAtIndex: 1];
		RepoButtonDelegate *rbd = (RepoButtonDelegate *)[mi target];
		if (!rbd) {
			activeBD = nil;
			return;
		}
		activeBD = rbd;
	});
}

@end
