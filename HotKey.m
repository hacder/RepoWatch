#import "HotKey.h"
#import <Carbon/Carbon.h>
#import "MainController.h"
#import "RepoButtonDelegate.h"

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
				[mc doCommitWindowForRepository: rbd];
				return noErr;
			}
			
			// Alright, let's let the user use the task switcher.
			[mc->tc showWindow];
			
			return noErr;
		}
	}
	return noErr;
}

void setup_hotkey(MainController *mc) {
	// Drop into Carbon in order to setup global hotkeys.
	EventHotKeyRef myHotKeyRef;
	EventHotKeyID myHotKeyID;
	EventTypeSpec eventType;
	
	eventType.eventClass = kEventClassKeyboard;
	eventType.eventKind = kEventHotKeyPressed;
	InstallApplicationEventHandler(&myHotKeyHandler, 1, &eventType, mc, NULL);
	myHotKeyID.signature = 'mhk1';
	myHotKeyID.id = 1;
	// 36 is Enter
	RegisterEventHotKey(36, cmdKey + optionKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
}