#import "RepoHelper.h"

@implementation RepoHelper

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

+ (NSString *)shortDiff: (RepoInstance *)repo {
	NSString *formatString = @"%s: %f files, +%a -%d";
	
	NSArray *arr = [formatString componentsSeparatedByString: @"%"];
	int i;
	NSString *result = [arr objectAtIndex: 0];
	for (i = 1; i < [arr count]; i++) {
		NSString *tmp = [arr objectAtIndex: i];
		if ([tmp length] == 0) {
			result = [NSString stringWithFormat: @"%@%%", result];
			i++;
		} else {
			unichar tmpchar = [tmp characterAtIndex: 0];
			tmp = [tmp substringFromIndex: 1];
			NSString *replacement = @"";
			switch (tmpchar) {
				// deletions
				case 'd':
					replacement = [NSString stringWithFormat: @"%d", [repo removedLines]];
					break;
				case 'a':
					replacement = [NSString stringWithFormat: @"%d", [repo addedLines]];
					break;
				case 'f':
					replacement = [NSString stringWithFormat: @"%d", [repo changedFiles]];
					break;
				case 's':
					replacement = [NSString stringWithFormat: @"%@", [[repo repository] lastPathComponent]];
					break;
			}
			result = [NSString stringWithFormat: @"%@%@%@", result, replacement, tmp];
		}
	}
	return result;
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