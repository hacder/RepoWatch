#import "MainController.h"
#import "ButtonDelegate.h"
#import "GitDiffButtonDelegate.h"
#import "MercurialDiffButtonDelegate.h"
#import "RepoButtonDelegate.h"
#import "Scanner.h"
#import "RepoHelper.h"
#import <Sparkle/Sparkle.h>
#import <AppKit/NSApplication.h>
#import "HotKey.h"

static MainController *shared;

@implementation MainController

+ (MainController *)sharedInstance {
	return shared;
}

- (void) commitFromMenu: (id) menu {
	[self doCommitWindowForRepository: [menu representedObject]];
}

/* This sets up the commit window for local or remote commits. */
- (void) doCommitWindowForRepository: (RepoButtonDelegate *)rbd {
	if (dispatch_get_current_queue() != dispatch_get_main_queue()) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self doCommitWindowForRepository: rbd];
		});
		return;
	}
	
	[commitWindow setTitle: [rbd shortTitle]];
	if ([rbd hasLocal]) {
		[[diffView textStorage] setAttributedString: [rbd colorizedDiff]];
		[tv setString: @""];
		
		// Ummm... isn't this guaranteed to be @"" thanks to the above?
		[rbd setCommitMessage: [tv string]];
		[butt setAction: @selector(commit:)];
	
		Diff *d = [rbd diff];
		[fileList setDataSource: d];
	} else {
		// TODO: Make this the upstream commit message.
		[tv setString: @""];
		[[diffView textStorage] setAttributedString: [rbd colorizedRemoteDiff]];
		[fileList setDataSource: nil];
	}

	[butt setEnabled: YES];
	[butt setTarget: rbd];
	[commitWindow makeFirstResponder: tv];
	[NSApp activateIgnoringOtherApps: YES];
	[commitWindow makeKeyAndOrderFront: self];
	[commitWindow center];
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

- (void) updater: (SUUpdater *)updater didFindValidUpdate: (SUAppcastItem *)item {
	[NSApp activateIgnoringOtherApps: YES];
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
	
	// Set up the repositories. This winds up working on a background thread, but we want to spawn that
	// thread as soon as possible, so that it finishes as soon as possible.
	scanner = [[Scanner alloc] init];

	setup_hotkey(self);
	
	// Set up Sparkle. Unfortunately I haven't started using this yet, and I'm not sure how to make it do the
	// updates correctly, but it's here already.
	SUUpdater *updater = [SUUpdater sharedUpdater];
	[updater setDelegate: self];
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *build = [infoDict objectForKey: @"CFBundleVersion"];
	
	NSURL *appcastURL = [NSURL URLWithString: [NSString stringWithFormat: @"http://www.doomstick.com/shine/appcast.php?id=7&uuid=%@&version=%@&osv=%f",
			[[NSUserDefaults standardUserDefaults] stringForKey: @"UUID"],
			[build stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding],
			NSAppKitVersionNumber]];
		NSLog(@"Using url: %@", appcastURL);
	[updater setFeedURL: appcastURL];
	[[SUUpdater sharedUpdater] checkForUpdatesInBackground];

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
