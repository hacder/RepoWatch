#import "RepoHelper.h"

@implementation RepoHelper

+ (NSAttributedString *)colorizedDiffFromArray: (NSArray *)arr {
	int i;
	NSMutableAttributedString *res = [[NSMutableAttributedString alloc] initWithString: @""];
	for (i = 0; i < [arr count]; i++) {
		NSString *thisLine = [arr objectAtIndex: i];
		NSAttributedString *newString;
		if ([thisLine characterAtIndex: 0] == '+') {
			newString = [[NSAttributedString alloc] initWithString: thisLine attributes: [NSDictionary dictionaryWithObject: [NSColor greenColor] forKey: NSForegroundColorAttributeName]];
		} else if ([thisLine characterAtIndex: 0] == '-') {
			newString = [[NSAttributedString alloc] initWithString: thisLine attributes: [NSDictionary dictionaryWithObject: [NSColor redColor] forKey: NSForegroundColorAttributeName]];			
		} else {
			newString = [[NSAttributedString alloc] initWithString: thisLine];
		}
		[res appendAttributedString: newString];
		[res appendAttributedString: [[NSAttributedString alloc] initWithString: @"\n"]];
	}
	return res;
}

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

+ (void)logTask: (NSTask *)task appending: (NSString *)appending {
	NSString *logString = [NSString stringWithFormat: @"%@ %@", [task currentDirectoryPath], [task launchPath]];
	NSArray *args = [task arguments];
	int i;
	for (i = 0; i < [args count]; i++) {
		logString = [NSString stringWithFormat: @"%@ %@", logString, [args objectAtIndex: i]];
	}
	if (appending)
		logString = [NSString stringWithFormat: @"%@ %@", logString, appending];
	NSLog(@"%@", logString);
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