#import <dirent.h>
#import <sys/stat.h>
#import "GitRepository.h"
#import "GitDiffButtonDelegate.h"

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
	if (self) {
		git = find_execable("git");
	}
	return self;
}

- (RepoButtonDelegate *)createRepository: (NSString *)path {
	if (git == nil)
		return nil;
	return [[GitDiffButtonDelegate alloc] initWithGit: git repository: path];
}

- (BOOL) validRepositoryContents: (NSArray *)contents {
	if (git == nil)
		return NO;
	
	return [contents containsObject: @".git"];
}


@end