#import "TimeMachineAlertButtonDelegate.h"

@implementation TimeMachineAlertButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mc];
	[self setHidden: YES];
	return self;
}

- (void) beep: (id) something {
	[self setShortTitle: @"TimeMachine running"];
	[self setTitle: @"TimeMachine running"]; 
	NSArray *stupid = [[[NSArray alloc] init] autorelease];
	NSTask *backupTask = [NSTask launchedTaskWithLaunchPath: @"/System/Library/CoreServices/backupd.bundle/Contents/Resources/backupd-helper" arguments: stupid];
	[backupTask launch];
}

- (void) fire {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults integerForKey: @"timeMachineEnabled"] == 0) {
		[self setTitle: @""];
		[self setShortTitle: @""];
		[self setHidden: YES];
		return;
	}
	
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: @"/Library/Preferences/com.apple.TimeMachine.plist"];
	if (!dict) {
		[self setHidden: YES];
		return;
	}
	
	BOOL b = [[dict objectForKey: @"AutoBackup"] boolValue];
	if (b == NO) {
		[self setHidden: YES];
		return;
	}
	
	dict = [NSDictionary dictionaryWithContentsOfFile: @"/var/db/.TimeMachine.Results.plist"];
	if (!dict) {
		[self setHidden: YES];
		return;
	}
	
	NSDate *backupDate = [dict objectForKey: @"BACKUP_COMPLETED_DATE"];
	int interval = (int)fabs([backupDate timeIntervalSinceNow]);
	int intMinutes = (interval / 60) % 60;
	int intHours = (interval / 3600);
	
	NSString *titular;
	if (intHours > [defaults integerForKey: @"timeMachineOverdueTime"]) {
		titular = [NSString stringWithFormat: @"TimeMachine Overdue!: %02dh:%02dm", intHours, intMinutes];
		[self setShortTitle: titular];
		[self setTitle: titular];
		[self setHidden: YES];
	} else {
		titular = [NSString stringWithFormat: @"TimeMachine last backup: %02dh:%02dm", intHours, intMinutes];
		[self setShortTitle: titular];
		[self setTitle: titular];
		[self setHidden: YES];
	}
}

@end