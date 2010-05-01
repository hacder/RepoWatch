#import "RepoTypeList.h"
#import "GitRepository.h"
#import "MercurialRepository.h"

@implementation RepoTypeList

RepoTypeList *sharedRepoTypeList;

+ (RepoTypeList *)sharedInstance {
	if (!sharedRepoTypeList)
		sharedRepoTypeList = [[RepoTypeList alloc] init];
	return sharedRepoTypeList;
}

- init {
	self = [super init];
	typeList = [NSArray arrayWithObjects:
		[GitRepository sharedInstance],
		[MercurialRepository sharedInstance],
		nil
	];
	return self;
}

- (RepoInstance *) createRepositoryWithPath: (NSString *)path directoryContents: (NSArray *)contents {
	int i;
	for (i = 0; i < [typeList count]; i++) {
		if ([[typeList objectAtIndex: i] validRepositoryContents: contents]) {
			return [[typeList objectAtIndex: i] createRepository: path];
		}
	}
	return nil;
}

@end