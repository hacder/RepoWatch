#import "HotKey.h"
#import <Carbon/Carbon.h>
#import "MainController.h"
#import "RepoInstance.h"

OSStatus myHotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
	MainController *mc = (MainController *)userData;
	
	int t = [mc->theMenu numberOfItems];
	int i;
	
	for (i = 0; i < t; i++) {
		NSMenuItem *mi = [mc->theMenu itemAtIndex: i];
		if (![[mi target] isKindOfClass: [RepoInstance class]])
			continue;

		RepoInstance *ri = (RepoInstance *)[mi target];
		if ([ri hasLocal]) {
			[ri localCommitWindow];
			return noErr;
		}
		return noErr;
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