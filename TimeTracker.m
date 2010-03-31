#import "TimeTracker.h"
#import "RepoButtonDelegate.h"

@implementation TimeTracker

- (void) addCommitMessage: (id) notification {
	RepoButtonDelegate *rbd = [notification object];
	NSString *message = [[notification userInfo] objectForKey: @"commitMessage"];
	
	NSMutableArray *arr = [timeTracks objectForKey: [rbd repository]];
	if (!arr)
		arr = [NSMutableArray arrayWithCapacity: 1];
	
	[arr addObject: message];
	[timeTracks setObject: arr forKey: [rbd repository]];
}

- (NSMutableArray *)getOnOffTimesForRBD: (RepoButtonDelegate *)rbd {
	NSDictionary *globalConfig = [[NSUserDefaults standardUserDefaults] objectForKey: @"cachedRepos"];
	NSDictionary *customConfig = [globalConfig objectForKey: [rbd repository]];
	NSArray *onofftimes = [customConfig objectForKey: @"onofftimes"];
	if (onofftimes)
		return [NSMutableArray arrayWithArray: onofftimes];
	return [NSMutableArray arrayWithCapacity: 1];
}

- (void) removeDuplicatesInList: (NSMutableArray *)onoff {
	int i;
	NSDate *lastOn = nil;
	BOOL currentlyOn = NO;

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
				// Duplicate offs? We need to be careful with our commit messages.
				
				NSArray *arr = [[onoff objectAtIndex: i] objectForKey: @"messsages"];
				if (arr) {
					NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [onoff objectAtIndex: i - 1]];
					[dict setObject: arr forKey: @"messages"];
					[onoff replaceObjectAtIndex: i - 1 withObject: dict];
				}
				[onoff removeObjectAtIndex: i];
			}
			
			// In any case, we must redo this index.
			i--;
			continue;
		}
		currentlyOn = setting;
	}
}

- (void) doWorkingChange: (id) notification {
	RepoButtonDelegate *rbd = [notification object];
	NSLog(@"doWorkingChange in TimeTracker for %@", rbd);

	// Get the list as it stands now.
	NSMutableArray *onoff = [self getOnOffTimesForRBD: rbd];
	NSLog(@"Initial: %@", onoff);

	// Create the new time item to be inserted.
	NSDictionary *item =
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSDate date], @"date",
			[NSNumber numberWithBool: [rbd hasLocal]], @"setting",
			[timeTracks objectForKey: [rbd repository]], @"messages",
			nil];
	[timeTracks removeObjectForKey: [rbd repository]];
	
	// Insert the object into the newly expanded array of onoff times.
	[onoff addObject: item];
	
	NSLog(@"Add item: %@", onoff);

	// Now we remove our duplicates.
	[self removeDuplicatesInList: onoff];	
	
	NSLog(@"Remove duplicates: %@", onoff);
	
	// Now, let's clean up the timers. This is tricky code that must be just right.
	BOOL currentlyOn = NO;
	int i;
	int seconds = 0;
	NSDate *lastOn = nil;
	NSDate *lastOff = nil;
	
	for (i = 0; i < [onoff count]; i++) {
		NSDictionary *dict = [onoff objectAtIndex: i];
		BOOL setting = [[dict objectForKey: @"setting"] boolValue];
		NSDate *ts = [dict objectForKey: @"date"];
		int timeInterval = 0;
		
		if (lastOn)
			timeInterval = [ts timeIntervalSinceDate: lastOn];
		
		// We have just turned on.
		if (setting) {
			// We are not the first time turning on, so there is a turn off time previously.
			if (lastOff) {
				// We spent less than 30 minutes turned off.
				if ([ts timeIntervalSinceDate: lastOff] < 60 * 30) {
					// If we have an off after this.
					if ([onoff count] > i + 1) {
						// We take our previous commit messages.
						NSArray *previousItems = [[onoff objectAtIndex: i - 1] objectForKey: @"messages"];
						
						// And append them to our next "off" time.
						NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary: [onoff objectAtIndex: i + 1]];
						
						NSArray *newArray;
						if ([dict objectForKey: @"messages"])
							newArray = [previousItems arrayByAddingObjectsFromArray: [dict objectForKey: @"messages"]];
						else
							newArray = previousItems;
							
						NSLog(@"New array: %@", newArray);
						if (newArray) {
							[dict setObject: newArray forKey: @"messages"];
							[onoff replaceObjectAtIndex: i + 1 withObject: dict];

							// Now we remove our previous off.
							[onoff removeObjectAtIndex: i - 1];
							[onoff removeObjectAtIndex: i - 1];
							i -= 2;
						}

						continue;
					}
					
				}
			}
			
		}
		
		if (setting) {
			lastOn = ts;
		} else {
			lastOff = ts;
			NSLog(@"Adding interval between %@ and %@", ts, lastOn);
			seconds += [ts timeIntervalSinceDate: lastOn];
		}
		currentlyOn = setting;
	}
	NSLog(@"Cleanup: %@", onoff);
	// NSLog(@"Time spent on %@: %02d:%02d:%02d",
	// 	[[rbd repository] lastPathComponent],
	// 	seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60);

	NSDictionary *globalConfig = [[NSUserDefaults standardUserDefaults] objectForKey: @"cachedRepos"];
	NSDictionary *customConfig = [globalConfig objectForKey: [rbd repository]];

	NSMutableDictionary *newCustomConfig = [NSMutableDictionary dictionaryWithDictionary: customConfig];
	[newCustomConfig setObject: onoff forKey: @"onofftimes"];
	
	NSMutableDictionary *newGlobalConfig = [NSMutableDictionary dictionaryWithDictionary: globalConfig];
	[newGlobalConfig setObject: newCustomConfig forKey: [rbd repository]];
	
	[[NSUserDefaults standardUserDefaults] setObject: newGlobalConfig forKey: @"cachedRepos"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- init {
	self = [super init];
	timeTracks = [[NSMutableDictionary alloc] init];
	[timeTracks retain];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(doWorkingChange:) name: @"repoModChange" object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(addCommitMessage:) name: @"repoCommit" object: nil];
	return self;
}

@end