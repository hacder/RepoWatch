#import "TaskQueue.h"
#import "RepoHelper.h"

@implementation TaskQueue

- initWithName: (NSString *)name {
	self = [super init];
	_name = [name retain];
	_custom_queue = dispatch_group_create();
	num_tasks = 0;
	return self;
}

- (void) addTask: (NSTask *)t withCallback: (void (^)(struct NSArray *))callback {
	num_tasks++;
	if (num_tasks == 1)
		NSLog(@"%@ is waking up", _name);
	dispatch_group_async(_custom_queue, dispatch_get_global_queue(0, 0), ^{
		NSFileHandle *file = [RepoHelper pipeForTask: t];
		NSFileHandle *err = [RepoHelper errForTask: t];

		[t launch];		
		NSString *string = [RepoHelper stringFromFile: file];
		NSArray *result = [string componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\0"]];
		[t waitUntilExit];
		if ([t terminationStatus] != 0) {
			[RepoHelper logTask: t appending: [NSString stringWithFormat: @"Error: %d", [t terminationStatus]]];
			(callback)(nil);
			num_tasks--;
			if (num_tasks == 0)
				NSLog(@"%@ is going to sleep", _name);
			return;
		}
		[err closeFile];
		[file closeFile];

		if ([[result objectAtIndex: [result count] - 1] isEqualToString: @""]) {
			NSMutableArray *result2 = [NSMutableArray arrayWithArray: result];
			[result2 removeObjectAtIndex: [result2 count] - 1];
			if (callback != nil)
				(callback)(result2);
			num_tasks--;
			if (num_tasks == 0)
				NSLog(@"%@ is going to sleep", _name);
			return;
		}

		if (callback != nil)
			(callback)(result);
		num_tasks--;
		if (num_tasks == 0)
			NSLog(@"%@ is going to sleep", _name);
		return;
	});
}

@end
