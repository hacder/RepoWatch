#import <dirent.h>
#import <sys/stat.h>
#import "MercurialRepository.h"

static MercurialRepository *shared = nil;

@implementation MercurialRepository

+ (MercurialRepository *)sharedInstance {
	if (shared == nil) {
		shared = [[MercurialRepository alloc] init];
		[shared retain];
	}
	return shared;
}

- init {
	self = [super init];
	if (self)
		executable = find_execable("hg");
	return self;
}

- (void) setRemoteChangeArguments: (NSTask *)t forRepository: (RepoInstance *)repo {
	[t setArguments: [NSArray arrayWithObjects: @"diff", @"--stat", nil]];
}

- (void) setLocalChangeArguments: (NSTask *)t forRepository: (RepoInstance *)repo {
	[t setArguments: [NSArray arrayWithObjects: @"diff", @"--stat", nil]];
}

- (void) setLogArguments: (NSTask *)t {
	[t setArguments: [NSArray arrayWithObjects: @"log", @"-l", @"10", @"--template", @"{node|short} {date} {desc|firstline}\n", nil]];
}

- (void) setLocalOnlyArguments: (NSTask *)t {
	[t setArguments: [NSArray arrayWithObjects: @"outgoing", @"-l", @"10", @"--template", @"{node|short}\n", nil]];
}

- (BOOL) validRepositoryContents: (NSArray *)contents {
	if (executable == nil)
		return NO;
	
	return [contents containsObject: @".hg"];
}


@end