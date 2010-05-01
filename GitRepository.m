#import <dirent.h>
#import <sys/stat.h>
#import "GitRepository.h"
#import "RepoInstance.h"
#import "RepoHelper.h"

static GitRepository *shared = nil;

@implementation GitRepository

+ (GitRepository *)sharedInstance {
	if (shared == nil) {
		shared = [[GitRepository alloc] init];
		[shared retain];
	}
	return shared;
}

- init {
	self = [super init];
	if (self)
		executable = find_execable("git");
	return self;
}

- (void) setLogArguments: (NSTask *)t {
	[t setArguments: [NSArray arrayWithObjects: @"log", @"-n", @"10", @"--pretty=%h %ct %s", nil]];
}

- (RepoInstance *)createRepository: (NSString *)path {
	if (executable == nil)
		return nil;
	return [[RepoInstance alloc] initWithRepoType: self shortTitle: [path lastPathComponent] path: path];
}

- (BOOL) validRepositoryContents: (NSArray *)contents {
	if (executable == nil)
		return NO;
	
	return [contents containsObject: @".git"];
}

@end