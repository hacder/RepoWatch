#import "RepoHelper.h"

@implementation RepoHelper

// This provides us with our name for the repository. In the future, the user will be able to
// adjust this with format flags. For now, just hard code (in one place) the policy that was
// hard coded in multiple places.
+ (NSString *)makeNameFromRepo: (RepoButtonDelegate *)repo {
	return [[repo repositoryPath] lastPathComponent];
}

+ (NSAttributedString *)colorizedDiffFromArray: (NSArray *)arr {
	int i;
	NSMutableAttributedString *res = [[NSMutableAttributedString alloc] initWithString: @""];
	NSAttributedString *newline = [[NSAttributedString alloc] initWithString: @"\n"];
	[newline autorelease];

	for (i = 0; i < [arr count]; i++) {
		NSString *thisLine = [arr objectAtIndex: i];
		if (![thisLine length]) {
			[res appendAttributedString: [[NSAttributedString alloc] initWithString: @"\n"]];
			continue;
		}
		NSFont *font;
		CGFloat fontSize = 14;
		NSColor *color;
		NSAttributedString *newString;
		if ([thisLine characterAtIndex: 0] == '+') {
			font = [NSFont boldSystemFontOfSize: fontSize];
			color = [NSColor greenColor];
		} else if ([thisLine characterAtIndex: 0] == '-') {
			font = [NSFont boldSystemFontOfSize: fontSize];
			color = [NSColor redColor];
		} else {
			font = [NSFont systemFontOfSize: fontSize];
			color = [NSColor grayColor];
		}
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: color, NSForegroundColorAttributeName, font, NSFontAttributeName, nil];
		newString = [[NSAttributedString alloc] initWithString: thisLine attributes: dict];
		[newString autorelease];
		[res appendAttributedString: newString];
		[res appendAttributedString: newline];
	}
	[res autorelease];
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