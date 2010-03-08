#import "MainController.h"
#import "ButtonDelegate.h"
#import "SeparatorButtonDelegate.h"
#import "QuitButtonDelegate.h"
#import "GitDiffButtonDelegate.h"
#import "MercurialDiffButtonDelegate.h"
#import "RepoButtonDelegate.h"
#import "Scanner.h"
#import "BubbleFactory.h"
#import <Sparkle/Sparkle.h>
#import <Carbon/Carbon.h>

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData);

@implementation MainController

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
	MainController *mc = (MainController *)userData;
	
	int t = [mc->theMenu numberOfItems];
	int i;
	for (i = 0; i < t; i++) {
		NSMenuItem *mi = [mc->theMenu itemAtIndex: i];
		if (![mi isHidden]) {
			if (![[mi target] isKindOfClass: [RepoButtonDelegate class]])
				continue;

			RepoButtonDelegate *rbd = (RepoButtonDelegate *)[mi target];
			if (!rbd)
				continue;

			if ([rbd hasUntracked]) {
				[rbd dealWithUntracked: nil];
				return noErr;
			}

			if ([rbd hasLocal]) {
				[rbd commit: nil];
				return noErr;
			}
			
			if ([rbd hasUpstream]) {
				[rbd pull: nil];
				return noErr;
			}
			
			return noErr;
		}
	}
	return noErr;
}

- (NSDictionary *)registrationDictionaryForGrowl {
	NSDictionary *dict = [NSDictionary
		dictionaryWithObjects:
			[NSArray arrayWithObjects: 
				[NSArray arrayWithObjects: @"testing", nil], nil]
		forKeys:
			[NSArray arrayWithObjects: GROWL_NOTIFICATIONS_ALL, nil]
	];
	return dict;
}

- init {
	self = [super init];
	activeBD = nil;
	currentRotation = [NSNumber numberWithFloat: 0.0];
	[currentRotation retain];
	
	[GrowlApplicationBridge setGrowlDelegate: self];
	[RepoButtonDelegate setupQueue];
	
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	statusItem = [bar statusItemWithLength: NSVariableStatusItemLength];
	[statusItem retain];
	
	[statusItem setTitle: NSLocalizedString(@"Starting Up...", @"")];
	[statusItem setHighlightMode: YES];
	theMenu = [[[NSMenu alloc] initWithTitle: @"Testing"] retain];
	[theMenu setAutoenablesItems: NO];
	
	[statusItem setMenu: theMenu];
	
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
	
	localSeparator = [NSMenuItem separatorItem];
	[localSeparator setHidden: YES];
	[theMenu addItem: localSeparator];
	upstreamSeparator = [NSMenuItem separatorItem];
	[upstreamSeparator setHidden: YES];
	[theMenu addItem: upstreamSeparator];
	normalSeparator = [NSMenuItem separatorItem];
	[normalSeparator setHidden: YES];  
	[theMenu addItem: normalSeparator];
	
	SUUpdater *updater = [SUUpdater sharedUpdater];
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *build = [infoDict objectForKey: @"CFBundleVersion"];
	
	[updater setFeedURL: [NSURL URLWithString: [NSString stringWithFormat: @"http://www.doomstick.com/mm_update_feed.xml?uuid=%@&version=%@",
			[[NSUserDefaults standardUserDefaults] stringForKey: @"UUID"],
			[build stringByAddingPercentEscapesUsingEncoding: NSASCIIStringEncoding]]]];
	[[SUUpdater sharedUpdater] checkForUpdatesInBackground];

	[theMenu addItem: [NSMenuItem separatorItem]];
	scanner = [[Scanner alloc] initWithTitle: @"Scan For Repositories" menu: theMenu statusItem: statusItem mainController: self];
	quit = [[QuitButtonDelegate alloc] initWithTitle: @"Quit" menu: theMenu statusItem: statusItem mainController: self];

	[self ping];
	
    return self;
}

- (IBAction) openFile: (id) sender {
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setCanChooseFiles: NO];
	[op setCanChooseDirectories: YES];
	[op setAllowsMultipleSelection: NO];

	// TODO: Find some way to verify directory before they hit OK.
	if ([op runModal] == NSOKButton) {
		NSString *filename = [op filename];
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: filename error: nil];

		NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
		NSDictionary *dict = [def dictionaryForKey: @"ignoredRepos"];
		NSMutableDictionary *dict2;
		if (dict) {
			dict2 = [NSMutableDictionary dictionaryWithDictionary: dict];
			[dict2 removeObjectForKey: filename];
			[def setObject: dict2 forKey: @"ignoredRepos"];
		}

		[scanner openFile: filename withContents: contents];
	}
}

NSInteger intSort(id num1, id num2, void *context) {
	return [[((RepoButtonDelegate *)num1) getShort] caseInsensitiveCompare: [((RepoButtonDelegate *)num2) getShort]];
}

- (void) maybeRefresh: (ButtonDelegate *)bd {
	if (![scanner isDone])
		return;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@"maybeRefresh");
		NSMutableArray *localMods = [NSMutableArray arrayWithCapacity: 10];
		NSMutableArray *remoteMods = [NSMutableArray arrayWithCapacity: 10];
		NSMutableArray *untrackedMods = [NSMutableArray arrayWithCapacity: 10];
		NSMutableArray *upToDate = [NSMutableArray arrayWithCapacity: 10];
		
		NSArray *arr = [RepoButtonDelegate getRepos];
		int i;
		for (i = 0; i < [arr count]; i++) {
			RepoButtonDelegate *bd2 = [arr objectAtIndex: i];
			if ([bd2 hasUntracked])
				[untrackedMods addObject: bd2];
			else if ([bd2 hasLocal])
				[localMods addObject: bd2];
			else if ([bd2 hasUpstream])
				[remoteMods addObject: bd2];
			else
				[upToDate addObject: bd2];
		}
		
		NSArray *localMods2 = [localMods sortedArrayUsingFunction: intSort context: nil];
		NSArray *upToDate2 = [upToDate sortedArrayUsingFunction: intSort context: nil];
		NSArray *remoteMods2 = [remoteMods sortedArrayUsingFunction: intSort context: nil];
		NSArray *untrackedMods2 = [untrackedMods sortedArrayUsingFunction: intSort context: nil];
		
		int index = 0;
		NSMenuItem *item;
		
		// One of these inserts is crashing.
		for (i = 0; i < [untrackedMods2 count]; i++) {
			item = [[untrackedMods2 objectAtIndex: i] getMenuItem];
			if (!item) {
				NSLog(@"Menu item is bad!?");
				continue;
			}
			[theMenu removeItem: item];
			[theMenu insertItem: item atIndex: ++index];
		}
		for (i = 0; i < [localMods2 count]; i++) {
			item = [[localMods2 objectAtIndex: i] getMenuItem];
			if (!item) {
				NSLog(@"Item is bad!?");
				continue;
			}
			[theMenu removeItem: item];
			[theMenu insertItem: item atIndex: ++index];
		}
		for (i = 0; i < [remoteMods2 count]; i++) {
			item = [[remoteMods2 objectAtIndex: i] getMenuItem];
			if (!item) {
				NSLog(@"Item is bad!?");
				continue;
			}
			[theMenu removeItem: item];
			[theMenu insertItem: item atIndex: ++index];
		}
		for (i = 0; i < [upToDate2 count]; i++) {
			item = [[upToDate2 objectAtIndex: i] getMenuItem];
			if (!item) {
				NSLog(@"Item is bad!?");
				continue;
			}
			[theMenu removeItem: item];
			[theMenu insertItem: item atIndex: ++index];
		}
		[theMenu setMenuChangedMessagesEnabled: YES];
	
		[self ping];
	});
}

- (void) timeout: (id) sender {
	[NSApp terminate: self];
}

#define PI 3.14159

+ (NSImage*)rotateImage: (NSImage*)orig byDegrees: (float)deg {
	NSImage *rotated = [[NSImage alloc] initWithSize:[orig size]];
	[rotated lockFocus];
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform rotateByDegrees:deg];
	[transform concat];
	[orig drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[rotated unlockFocus];
	[orig autorelease];
	return [rotated autorelease];
}

- (void) setProperIconForButton: (RepoButtonDelegate *)rbd atRotationOf: (NSNumber *)rot withString: (BOOL)withString {
		NSLog(@"Animation update: %@", rot);
		NSApplication *app = [NSApplication sharedApplication];
		if ([rbd hasUntracked]) {
			[app setApplicationIconImage: [[BubbleFactory getBlueOfSize: [[app dockTile] size].height] autorelease]];
			[statusItem setImage: [MainController rotateImage: [BubbleFactory getBlueOfSize: 15] byDegrees: [rot floatValue]]];
			if (withString)
				[statusItem setTitle: [rbd shortTitle]];
		} else if ([rbd hasLocal]) {
			[app setApplicationIconImage: [[BubbleFactory getRedOfSize: [[app dockTile] size].height] autorelease]];
			[statusItem setImage: [MainController rotateImage: [BubbleFactory getRedOfSize: 15] byDegrees: [rot floatValue]]];
			if (withString)
				[statusItem setTitle: [rbd shortTitle]];
		} else if ([rbd hasUpstream]) {
			[app setApplicationIconImage: [[BubbleFactory getYellowOfSize: [[app dockTile] size].height] autorelease]];
			[statusItem setImage: [MainController rotateImage: [BubbleFactory getYellowOfSize: 15] byDegrees: [rot floatValue]]];
			if (withString)
				[statusItem setTitle: [rbd shortTitle]];
		} else {
			[app setApplicationIconImage: [[BubbleFactory getGreenOfSize: [[app dockTile] size].height] autorelease]];
			[statusItem setImage: [MainController rotateImage: [BubbleFactory getGreenOfSize: 15] byDegrees: [rot floatValue]]];
			[statusItem setTitle: @""];
		}	
}

- (void) ping {
	if (![scanner isDone])
		return;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		NSMenuItem *mi = [theMenu itemAtIndex: 1];
		RepoButtonDelegate *rbd = (RepoButtonDelegate *)[mi target];
		if (!rbd) {
			activeBD = nil;
			return;
		}
		activeBD = rbd;
	
		int noString = [[NSUserDefaults standardUserDefaults] integerForKey: @"suppressText"];
		if (noString)
			[statusItem setTitle: @""];
		
		[self setProperIconForButton: rbd atRotationOf: currentRotation withString: !noString];
	});
}

- (void) animationUpdate: (id) timer {
	if (currentRotation) {
		float newVal = [currentRotation floatValue] + 1.0;
		[currentRotation autorelease];
		currentRotation = [NSNumber numberWithFloat: newVal];
		[currentRotation retain];
	}
	if (activeBD)
		[self setProperIconForButton: (RepoButtonDelegate *)activeBD atRotationOf: currentRotation withString: [[NSUserDefaults standardUserDefaults] integerForKey: @"suppressText"]];
}

- (void) setAnimatingFor: (ButtonDelegate *)bd to: (BOOL)b {
	if (activeBD && activeBD == bd) {
		if (b) {
			// We already have an animation timer, so let's just keep using that one.
			if (animationTimer)
				return;
			animationTimer = [NSTimer scheduledTimerWithTimeInterval: 0.1 target: self selector: @selector(animationUpdate:) userInfo: nil repeats: YES];
//		} else {
//			if (animationTimer)
//				[animationTimer invalidate];
//			animationTimer = nil;
//			[currentRotation autorelease];
//			currentRotation = [NSNumber numberWithFloat: 0.0];
//			[currentRotation retain];
		}
	}
}

@end
