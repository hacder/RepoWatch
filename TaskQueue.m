#import "TaskQueue.h"
#import "RepoHelper.h"

@implementation TaskQueue

- initWithName: (NSString *)name {
	self = [super init];
	_name = [name retain];
//	_custom_queue = dispatch_queue_create([name cStringUsingEncoding: NSASCIIStringEncoding], NULL);
	_custom_queue = dispatch_group_create();
//	dispatch_set_target_queue(_custom_queue, dispatch_get_global_queue(0, 0));
	return self;
}

- (void) addTask: (NSTask *)t withCallback: (void (^)(struct NSArray *))callback {
	NSLog(@"addTask called via %s", dispatch_queue_get_label(dispatch_get_current_queue()));
	dispatch_group_async(_custom_queue, dispatch_get_global_queue(0, 0), ^{
		NSLog(@"now inside %s", dispatch_queue_get_label(dispatch_get_current_queue()));
		NSFileHandle *file = [RepoHelper pipeForTask: t];
		NSFileHandle *err = [RepoHelper errForTask: t];

		[t launch];		
		NSString *string = [RepoHelper stringFromFile: file];
		NSArray *result = [string componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\0"]];
		[t waitUntilExit];
		if ([t terminationStatus] != 0) {
			[RepoHelper logTask: t appending: [NSString stringWithFormat: @"Error: %d", [t terminationStatus]]];
			return;
		}
		[err closeFile];
		[file closeFile];

		if ([[result objectAtIndex: [result count] - 1] isEqualToString: @""]) {
			NSMutableArray *result2 = [NSMutableArray arrayWithArray: result];
			[result2 removeObjectAtIndex: [result2 count] - 1];
			if (callback != nil) {
				NSLog(@"Starting callback");
				(callback)(result2);
				NSLog(@"Done callback");
			}
			return;
		}

		if (callback != nil) {
			NSLog(@"Starting callback via 2");
			(callback)(result);
			NSLog(@"Ending callback via 2");
		}
		return;
	});
		
//	NSLog(@"There are %d tasks", [tasks count]);
}

@end
