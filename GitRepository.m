#import <dirent.h>
#import <sys/stat.h>
#import "GitRepository.h"
#import "RepoHelper.h"
#import "RepoInstance.h"

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
	remoteName = nil;
	return self;
}

- (void) setRemoteChangeArguments: (NSTask *)t forRepository: (RepoInstance *)repo {
	[t setArguments: [NSArray arrayWithObjects: @"diff", nil]];
}

- (void) setLocalChangeArguments: (NSTask *)t forRepository: (RepoInstance *)repo {
	[t setArguments: [NSArray arrayWithObjects: @"diff", nil]];
}

- (void) setLogArguments: (NSTask *)t forRepository: (RepoInstance *)data {
	[t setArguments: [NSArray arrayWithObjects: @"log", @"-n", @"10", @"--pretty=%h %ct %s", nil]];
}

- (void) setLocalOnlyArguments: (NSTask *)t forRepository: (RepoInstance *)data {
	NSString *s = [NSString stringWithFormat: @"master...%@/master", [[data dict] objectForKey: @"remoteName"]];
	[t setArguments: [NSArray arrayWithObjects: @"log", @"-n", @"10", @"--pretty=%h", s, nil]];
}

- (BOOL) validRepositoryContents: (NSArray *)contents {
	if (executable == nil)
		return NO;
	
	return [contents containsObject: @".git"];
}

- (BOOL) hasRemoteWithRepository: (RepoInstance *)data {
	NSMutableDictionary *dict = [data dict];
	if ([dict objectForKey: @"hasCheckedRemote"])
		return [[dict objectForKey: @"hasRemote"] boolValue];

	NSTask *t = [self baseTaskWithRepository: data];
	[t setArguments: [NSArray arrayWithObjects: @"remote", nil]];	
	NSFileHandle *file = [RepoHelper pipeForTask: t];
	[t launch];
	NSString *string = [RepoHelper stringFromFile: file];
	string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (![string isEqualToString: @""]) {
		remoteName = string;
		[remoteName retain];
		[dict setObject: @"1" forKey: @"hasRemote"];
		[dict setObject: remoteName forKey: @"remoteName"];
	} else {
		[dict setObject: @"0" forKey: @"hasRemote"];
	}
	[dict setObject: @"1" forKey: @"hasCheckedRemote"];
	return [[dict objectForKey: @"hasRemote"] boolValue];
}

@end