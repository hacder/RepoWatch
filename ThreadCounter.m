#import "ThreadCounter.h"

@implementation ThreadCounter

static int num_threads = 0;
static int max_threads = 0;

+ (void) debug {
	NSLog(@"There are %d threads currently", num_threads);
}

+ (void) exitSection {
	num_threads--;
}

+ (void) enterSection {
	num_threads++;
	if (num_threads > max_threads) {
		max_threads = num_threads;
		NSLog(@"Just broke thread count record: %d", num_threads);
	}
}

@end 