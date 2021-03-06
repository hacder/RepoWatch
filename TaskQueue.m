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

- (void) decrementTaskCount {
	num_tasks--;
}

- (void) doCallback: (void (^)(struct NSArray *))callback withResult: (NSArray *)result {
	if (callback != nil)
		(callback)(result);
	[self decrementTaskCount];
}

- (void) handleOddTerminationStatusOfTask: (NSTask *)t withCallback: (void (^)(struct NSArray *))callback {
	[RepoHelper logTask: t appending: [NSString stringWithFormat: @"Error: %d", [t terminationStatus]]];
	[self doCallback: callback withResult: nil];
}

- (void) addTask: (NSTask *)t withCallback: (void (^)(struct NSArray *))callback {
	num_tasks++;
	dispatch_group_async(_custom_queue, dispatch_get_global_queue(0, 0), ^{
		NSFileHandle *file = [RepoHelper pipeForTask: t];
		NSFileHandle *err = [RepoHelper errForTask: t];

		[t launch];
		NSString *string = [RepoHelper stringFromFile: file];
		NSArray *result = [string componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\0"]];
		[t waitUntilExit];
		if ([t terminationStatus] != 0) {
			[self handleOddTerminationStatusOfTask: t withCallback: callback];
			return;
		}
		[err closeFile];
		[file closeFile];

		if ([[result objectAtIndex: [result count] - 1] isEqualToString: @""]) {
			NSMutableArray *result2 = [NSMutableArray arrayWithArray: result];
			[result2 removeObjectAtIndex: [result2 count] - 1];
			[self doCallback: callback withResult: result2];
			return;
		}

		[self doCallback: callback withResult: result];
		return;
	});
}

@end
