#import "TimeTracker.h"
#import "RepoButtonDelegate.h"

@implementation TimeTracker

- (void) addCommitMessage: (id) notification {
	RepoButtonDelegate *rbd = [notification object];
	NSString *message = [[notification userInfo] objectForKey: @"commitMessage"];
	NSLog(@"%@ used message %@", rbd, message);
}

- (void) doWorkingChange: (id) notification {
	RepoButtonDelegate *rbd = [notification object];
	
	// Create the new time item to be inserted.
	NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys: [NSDate date], @"date", [NSNumber numberWithBool: [rbd hasLocal]], @"setting", nil];
	
	NSDictionary *globalConfig = [[NSUserDefaults standardUserDefaults] objectForKey: @"cachedRepos"];
	NSDictionary *customConfig = [globalConfig objectForKey: [rbd repository]];
	NSArray *onofftimes = [customConfig objectForKey: @"onofftimes"];
	NSMutableArray *onoff;
	if (onofftimes == nil) {
		onoff = [NSMutableArray arrayWithCapacity: 1];
	} else {
		// Make it mutable.
		onoff = [NSMutableArray arrayWithArray: onofftimes];
	}
	
	// Insert the object into the newly expanded array of onoff times.
	[onoff addObject: item];
	
	// Now, let's clean up the timers. This is tricky code that must be just right.
	BOOL currentlyOn = NO;
	int i;
	int seconds = 0;
	NSDate *lastOn = nil;
	
	for (i = 0; i < [onoff count]; i++) {
		NSDictionary *dict = [onoff objectAtIndex: i];
		BOOL setting = [[dict objectForKey: @"setting"] boolValue];
		NSDate *ts = [dict objectForKey: @"date"];
		int timeInterval = 0;
		
		if (lastOn)
			timeInterval = [ts timeIntervalSinceDate: lastOn];
		
		// If we have a duplicate, we want to remove one of them.
		if (setting == currentlyOn) {
			
			// If we have more than one "on" events, then we left it on and we crashed or were quit. How much time
			// passed?
			if (setting) {
				
				// If it has been more than an hour, then we probably went off and did something else. Discard this
				// section of time by removing the previous On entry. Otherwise, we count the time and remove THIS
				// on entry just to make things cleaner.
				if (timeInterval > 3600) {
					[onoff removeObjectAtIndex: i - 1];
					lastOn = ts;
				} else {
					[onoff removeObjectAtIndex: i];
				}
			} else {
				// Duplicate offs? That's simple, always remove the second one!
				[onoff removeObjectAtIndex: i];
			}
			
			// In any case, we must redo this index.
			i--;
			continue;
		}
		
		if (setting) {
			lastOn = ts;
		} else {
			seconds += [ts timeIntervalSinceDate: lastOn];
		}
		currentlyOn = setting;
	}
	NSLog(@"Time spent on %@: %02d:%02d:%02d",
		[[rbd repository] lastPathComponent],
		seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60);

	NSMutableDictionary *newCustomConfig = [NSMutableDictionary dictionaryWithDictionary: customConfig];
	[newCustomConfig setObject: onoff forKey: @"onofftimes"];
	
	NSMutableDictionary *newGlobalConfig = [NSMutableDictionary dictionaryWithDictionary: globalConfig];
	[newGlobalConfig setObject: newCustomConfig forKey: @"cachedRepos"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- init {
	self = [super init];
	timeTracks = [NSMutableArray arrayWithCapacity: 10];
	[timeTracks retain];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(doWorkingChange:) name: @"repoModChange" object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(addCommitMessage:) name: @"repoAddCommit" object: nil];
	return self;
}

@end