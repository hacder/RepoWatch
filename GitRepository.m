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

- (BOOL) logFromToday: (RepoButtonDelegate *)data {
	NSArray *logs = [data logs];
	if (![logs count])
		return NO;
		
	NSString *currentPiece = [logs objectAtIndex: 0];
	NSArray *pieces = [currentPiece componentsSeparatedByString: @" "];
	NSString *timestamp = [pieces objectAtIndex: 1];

	NSDate *then = [NSDate dateWithTimeIntervalSince1970: [timestamp intValue]];
	NSTimeInterval interval = -1 * [then timeIntervalSinceNow];
	if (interval < 60 * 60 * 48)
		return YES;

	return NO;
}


@end