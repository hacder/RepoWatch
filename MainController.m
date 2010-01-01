#import "MainController.h"
#import "ButtonDelegate.h"
#import "SeparatorButtonDelegate.h"
#import "QuitButtonDelegate.h"
#import "GitDiffButtonDelegate.h"
#import "MercurialDiffButtonDelegate.h"
#import "RepoButtonDelegate.h"
#import "Scanner.h"
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
			RepoButtonDelegate *rbd = (RepoButtonDelegate *)[mi target];
			[rbd commit: nil];
			return noErr;
		}
	}
	return noErr;
}

- (NSImage *)getBubbleOfColor: (NSColor *)highlightColor {
	int size = 15;
	NSColor *color = [highlightColor blendedColorWithFraction: 0.75 ofColor: [NSColor whiteColor]];
	NSImage *ret = [[NSImage alloc] initWithSize: NSMakeSize(size, size)];
	[ret lockFocus];
	NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(1.0, 1.0, size - 2.0, size - 2.0)];
	NSGradient *aGradient = [[[NSGradient alloc] initWithStartingColor: color endingColor: highlightColor] autorelease];
	[aGradient drawInBezierPath: path relativeCenterPosition: NSMakePoint(0.2, 0.2)];
	[path setLineWidth: 2];
	[[NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 0.5 alpha: 1.0] set];
	[path stroke];
	[ret unlockFocus];
	return ret;
}

- init {
	self = [super init];
	date = __DATE__;
	time = __TIME__;
	
	redBubble = [self getBubbleOfColor: [NSColor colorWithCalibratedRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0]];
	yellowBubble = [self getBubbleOfColor: [NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 0.0 alpha: 1.0]];
	greenBubble = [self getBubbleOfColor: [NSColor colorWithCalibratedRed: 0.75 green: 0.75 blue: 0.75 alpha: 1.0]];

	NSDate *expires = [NSDate dateWithNaturalLanguageString: [NSString stringWithFormat: @"%s", date]];
	
	// 30 days from compilation.
	expires = [NSDate dateWithTimeInterval: 3600 * 24 * 30 sinceDate: expires];
	demoTimer = [[NSTimer alloc] initWithFireDate: expires interval: 10 target: self selector: @selector(timeout:) userInfo: nil repeats: NO];
	[demoTimer retain];
	[[NSRunLoop currentRunLoop] addTimer: demoTimer forMode: NSDefaultRunLoopMode];
	
	NSLog(@"Expires at: %@\n", expires);
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	statusItem = [bar statusItemWithLength: NSVariableStatusItemLength];
	[statusItem retain];
	
	[statusItem setTitle: NSLocalizedString(@"RepoWatch", @"")];
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
	[updater setFeedURL: [NSURL URLWithString: [NSString stringWithFormat: @"http://www.doomstick.com/mm_update_feed.xml?uuid=%@", [[NSUserDefaults standardUserDefaults] stringForKey: @"UUID"]]]];
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
	return [((RepoButtonDelegate *)num1)->shortTitle caseInsensitiveCompare: ((RepoButtonDelegate *)num2)->shortTitle];
}

- (void) maybeRefresh: (ButtonDelegate *)bd {
	if (![scanner isDone])
		return;
	NSMutableArray *localMods = [NSMutableArray arrayWithCapacity: 10];
	NSMutableArray *remoteMods = [NSMutableArray arrayWithCapacity: 10];
	NSMutableArray *upToDate = [NSMutableArray arrayWithCapacity: 10];
	
	NSArray *arr = [RepoButtonDelegate getRepos];
	int i;
	for (i = 0; i < [arr count]; i++) {
		RepoButtonDelegate *bd2 = [arr objectAtIndex: i];
		if (bd2->localMod)
			[localMods addObject: bd2];
		else if (bd2->upstreamMod)
			[remoteMods addObject: bd2];
		else
			[upToDate addObject: bd2];
	}
	
	NSArray *localMods2 = [localMods sortedArrayUsingFunction: intSort context: nil];
	NSArray *upToDate2 = [upToDate sortedArrayUsingFunction: intSort context: nil];
	NSArray *remoteMods2 = [remoteMods sortedArrayUsingFunction: intSort context: nil];
	
	[theMenu setMenuChangedMessagesEnabled: NO];
	int index = 0;
	for (i = 0; i < [localMods2 count]; i++) {
		[theMenu removeItem: [[localMods2 objectAtIndex: i] getMenuItem]];
		[theMenu insertItem: [[localMods2 objectAtIndex: i] getMenuItem] atIndex: ++index];
	}
	for (i = 0; i < [remoteMods2 count]; i++) {
		[theMenu removeItem: [[remoteMods2 objectAtIndex: i] getMenuItem]];
		[theMenu insertItem: [[remoteMods2 objectAtIndex: i] getMenuItem] atIndex: ++index];
	}
	for (i = 0; i < [upToDate2 count]; i++) {
		[theMenu removeItem: [[upToDate2 objectAtIndex: i] getMenuItem]];
		[theMenu insertItem: [[upToDate2 objectAtIndex: i] getMenuItem] atIndex: ++index];
	}
	[theMenu setMenuChangedMessagesEnabled: YES];

	[self ping];
}

- (void) timeout: (id) sender {
	[NSApp terminate: self];
}

- (void) ping {
	int localMods = [RepoButtonDelegate numLocalEdit];
	int remoteMods = [RepoButtonDelegate numRemoteEdit];
	
	if (localMods || remoteMods) {
		if (localMods)
			[statusItem setImage: redBubble];
		else if (remoteMods)
			[statusItem setImage: yellowBubble];
		
		NSMenuItem *mi = [theMenu itemAtIndex: 1];
		RepoButtonDelegate *rbd = (RepoButtonDelegate *)[mi target];
		[statusItem setTitle: [rbd shortTitle]];
	} else {
		[statusItem setImage: greenBubble];
		[statusItem setTitle: @""];
	}
}

@end
