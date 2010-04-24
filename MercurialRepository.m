#import <dirent.h>
#import <sys/stat.h>
#import "MercurialRepository.h"
#import "MercurialDiffButtonDelegate.h"

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
	if (self) {
		hg = find_execable("hg");
	}
	return self;
}

- (RepoButtonDelegate *)createRepository: (NSString *)path {
	if (hg == nil)
		return nil;
	return [[MercurialDiffButtonDelegate alloc] initWithHG: hg repository: path];
}

- (BOOL) validRepositoryContents: (NSArray *)contents {
	if (hg == nil)
		return NO;
	
	return [contents containsObject: @".hg"];
}


@end