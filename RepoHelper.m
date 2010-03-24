#import "RepoHelper.h"

@implementation RepoHelper

+ (NSString *)shortenDiff: (NSString *)diff {
	NSArray *parts = [diff componentsSeparatedByString: @", "];
	if ([parts count] == 3) {
		int num_files = [[parts objectAtIndex: 0] intValue];
		int num_plus = [[parts objectAtIndex: 1] intValue];
		int num_minus = [[parts objectAtIndex: 2] intValue];
		
		if (!num_plus && !num_minus)
			return nil;
		NSString *ret = [NSString stringWithFormat: @"%d files, +%d -%d", num_files, num_plus, num_minus];
		return ret;
	} else {
		return diff;
	}
}

+ (NSString *)stringFromFile: (NSFileHandle *)file {
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[[NSString alloc] initWithData: data
			encoding: NSUTF8StringEncoding] autorelease];
	return string;
}

+ (NSFileHandle *)pipeForTask: (NSTask *)t {
	NSPipe *pipe = [NSPipe pipe];
	[t setStandardOutput: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	return file;
}

+ (NSFileHandle *)errForTask: (NSTask *)t {
	NSPipe *pipe = [NSPipe pipe];
	[t setStandardError: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	return file;
}

@end