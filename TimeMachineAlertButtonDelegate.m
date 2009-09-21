#import "TimeMachineAlertButtonDelegate.h"

@implementation TimeMachineAlertButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	return self;
}

- (void) beep: (id) something {
	[self setShortTitle: @"TimeMachine running"];
	[self setTitle: @"TimeMachine running"]; 
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		NSTask *backupTask = [NSTask launchedTaskWithLaunchPath: @"/System/Library/CoreServices/backupd.bundle/Contents/Resources/backupd-helper" arguments: nil];
		[backupTask launch];
		[self forceRefresh];
	});
}

- (void) fire {
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: @"/var/db/.TimeMachine.Results.plist"];
	if (!dict) {
		[self setHidden: TRUE];
		return;
	}
	[self setHidden: FALSE];
	NSDate *backupDate = [dict objectForKey: @"BACKUP_COMPLETED_DATE"];
	int interval = (int)fabs([backupDate timeIntervalSinceNow]);
	int intMinutes = (interval / 60) % 60;
	int intHours = (interval / 3600);
	
	NSString *titular;
	if (intHours > 10) {
		titular = [NSString stringWithFormat: @"TimeMachine Overdue!: %02dh:%02dm", intHours, intMinutes];
		[self setShortTitle: titular];
		[self setTitle: titular];
		[self setPriority: 26];
	} else {
		titular = [NSString stringWithFormat: @"TimeMachine last backup: %02dh:%02dm", intHours, intMinutes];
		[self setShortTitle: titular];
		[self setTitle: titular];
		[self setPriority: 3];
	}
}

@end