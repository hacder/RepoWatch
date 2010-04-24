#import <dirent.h>
#import <sys/stat.h>
#import "MercurialRepository.h"
#import "MercurialDiffButtonDelegate.h"

@implementation MercurialRepository

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