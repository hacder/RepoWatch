#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// A single-thread backgrounded queue of NSTasks to run, complete with GCD callback, running on the same queue.

@interface TaskQueue : NSObject {
	NSMutableArray *tasks;
	NSString *_name;
	dispatch_queue_t _custom_queue;
}

- initWithName: (NSString *)name;
- (void) addTask: (NSTask *)t withCallback: (void (^)(struct NSArray *))callback;

@end