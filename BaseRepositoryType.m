#import <dirent.h>
#import <sys/stat.h>
#import "BaseRepositoryType.h"
#import "RepoHelper.h"

@implementation BaseRepositoryType

- (BOOL) validRepositoryContents: (NSArray *)contents {
	return NO;
}

- (void) setLogArguments: (NSTask *)t forRepository: (RepoInstance *)data {
}

- (void) setLocalOnlyArguments: (NSTask *)t forRepository: (RepoInstance *)data {
}

- (void) setRemoteChangeArguments: (NSTask *)t forRepository: (RepoInstance *)repo {
}

- (void) setLocalChangeArguments: (NSTask *)t forRepository: (RepoInstance *)repo {
}

- (NSString *) localDiffArray: (NSArray *)result toStringWithRepository: (RepoInstance *)repo {
	return @"";
}

- (NSString *) remoteDiffArray: (NSArray *)result toStringWithRepository: (RepoInstance *)repo {
	return @"";
}

- (void) checkLocalChangesWithRepository: (RepoInstance *)repo {
	NSTask *t = [self baseTaskWithRepository: repo];
	[self setRemoteChangeArguments: t forRepository: repo];
	
	NSFileHandle *file = [RepoHelper pipeForTask: t];
	[t launch];
	NSString *string = [RepoHelper stringFromFile: file];
	NSArray *result = [string componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\0"]];	
	NSString *shrt = [self localDiffArray: result toStringWithRepository: repo];
	if (!shrt || [shrt isEqualToString: @""]) {
		[[repo dict] removeObjectForKey: @"localDiff"];
	} else {
		[[repo dict] setObject: shrt forKey: @"localDiff"];
	}
}

- (void) checkRemoteChangesWithRepository: (RepoInstance *)repo {
	NSTask *t = [self baseTaskWithRepository: repo];
	[self setRemoteChangeArguments: t forRepository: repo];
	
	NSFileHandle *file = [RepoHelper pipeForTask: t];
	[t launch];
	NSString *string = [RepoHelper stringFromFile: file];
	NSArray *result = [string componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\0"]];	
	NSString *shrt = [self remoteDiffArray: result toStringWithRepository: repo];
	
	if (!shrt || [shrt isEqualToString: @""]) {
		[[repo dict] removeObjectForKey: @"remoteDiff"];
	} else {
		[[repo dict] setObject: shrt forKey: @"remoteDiff"];
	}
}

- (BOOL) hasRemoteWithRepository: (RepoInstance *)data {
	return NO;
}

- (BOOL) hasLocalWithRepository: (RepoInstance *)data {
	if ([[data dict] objectForKey: @"localDiff"] != nil)
		return YES;
	return NO;
}

- (NSDictionary *) handleSingleLogLineAsArray: (NSArray *)pieces {
	NSString *timestamp = [pieces objectAtIndex: 1];
	NSString *hash = [pieces objectAtIndex: 0];

	NSRange theRange;
	theRange.location = 2;
	theRange.length = [pieces count] - 2;

	NSArray *logMessage = [pieces subarrayWithRange: theRange];
	NSString *logString = [logMessage componentsJoinedByString: @" "];
	
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	[dict setObject: [NSDate dateWithTimeIntervalSince1970: [timestamp intValue]] forKey: @"date"];
	[dict setObject: hash forKey: @"hash"];
	[dict setObject: logString forKey: @"message"];
	return dict;
}

- (RepoInstance *)createRepository: (NSString *)path {
	if (executable == nil)
		return nil;
	return [[RepoInstance alloc] initWithRepoType: self shortTitle: [path lastPathComponent] path: path];
}

- (NSTask *)baseTaskWithRepository: (RepoInstance *)repo {
	NSTask *t = [[NSTask alloc] init];
	[t setLaunchPath: [NSString stringWithCString: executable encoding: NSUTF8StringEncoding]];
	[t setCurrentDirectoryPath: [repo repository]];
	[t autorelease];
	return t;
}

- (void) pendingLogsWithRepository: (RepoInstance *)repo {
	NSTask *t = [self baseTaskWithRepository: repo];
	[self setLocalOnlyArguments: t forRepository: repo];
	
	NSFileHandle *file = [RepoHelper pipeForTask: t];
	[t launch];
	NSString *string = [RepoHelper stringFromFile: file];
	NSArray *result = [string componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\0"]];
	
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity: [result count]];
	
	int i;
	for (i = 0; i < [result count]; i++) {
		NSString *singleLog = [result objectAtIndex: i];
		if ([singleLog isEqualToString: @""])
			continue;
		[arr addObject: singleLog];
	}
	[[repo dict] setObject: arr forKey: @"pending"];
}

- (void) updateLogsWithRepository: (RepoInstance *)repo {
	NSTask *t = [self baseTaskWithRepository: repo];
	[self setLogArguments: t forRepository: repo];
	
	NSFileHandle *file = [RepoHelper pipeForTask: t];
	[t launch];
	NSString *string = [RepoHelper stringFromFile: file];
	NSArray *result = [string componentsSeparatedByCharactersInSet: [NSCharacterSet characterSetWithCharactersInString: @"\n\0"]];
	
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity: [result count]];
	
	int i;
	for (i = 0; i < [result count]; i++) {
		NSString *singleLog = [result objectAtIndex: i];
		if ([singleLog isEqualToString: @""])
			continue;

		NSArray *pieces = [singleLog componentsSeparatedByString: @" "];
		NSDictionary *dict = [self handleSingleLogLineAsArray: pieces];
		if (dict)
			[arr addObject: dict];
	}
	[[repo dict] setObject: arr forKey: @"logs"];
	if ([[[repo dict] objectForKey: @"hasRemote"] boolValue])
		[self pendingLogsWithRepository: repo];
}

- (NSArray *) pendingWithRepository: (RepoInstance *)rep {
	NSMutableDictionary *data = [rep dict];
	NSArray *pending = [data objectForKey: @"pending"];
	return pending;
}

- (NSArray *) logsWithRepository: (RepoInstance *)rep {
	NSMutableDictionary *data = [rep dict];
	NSArray *logs = [data objectForKey: @"logs"];
	return logs;
}

- (BOOL) logFromTodayWithRepository: (RepoInstance *)rep {
	NSMutableDictionary *data = [rep dict];
	NSDate *lastLogUpdate = [data objectForKey: @"lastLogUpdate"];

	if (!lastLogUpdate || [lastLogUpdate timeIntervalSinceNow] > 60 * 5) {
		[self updateLogsWithRepository: rep];
		[data setObject: [NSDate date] forKey: @"lastLogUpdate"];
	}
	
	NSArray *logs = [data objectForKey: @"logs"];
	if (logs == nil)
		return NO;
	if ([logs count] == 0)
		return NO;
		
	NSDictionary *log = [logs objectAtIndex: 0];
	NSDate *logDate = [log objectForKey: @"date"];
	
	int timeInterval = -1 * [logDate timeIntervalSinceNow];	
	if (timeInterval > 60 * 60 * 24)
		return NO;
	return YES;
}

@end

char *find_execable(const char *filename) {
	char *path, *p, *n;
	struct stat s;
	
	p = path = strdup(getenv("PATH"));
	while (p) {
		n = strchr(p, ':');
		if (n)
			*n++ = '\0';
		if (*p != '\0') {
			p = concat_path_file(p, filename);
			if (!access(p, X_OK) && !stat(p, &s) && S_ISREG(s.st_mode)) {
				free(path);
				return p;
			}
			free(p);
		}
		p = n;
	}
	
	// Because the mac is odd sometimes, let's look in a few places that may not
	// be in the path.
	
	n = concat_path_file("/opt/local/bin/", filename);
	if (!access(n, X_OK) && !stat(n, &s) && S_ISREG(s.st_mode))
		return n;
	free(n);

	n = concat_path_file("/sw/bin/", filename);
	if (!access(n, X_OK) && !stat(n, &s) && S_ISREG(s.st_mode))
		return n;
	free(n);

	n = concat_path_file("/usr/local/bin/", filename);
	if (!access(n, X_OK) && !stat(n, &s) && S_ISREG(s.st_mode))
		return n;
	free(n);
	
	n = concat_path_file("/usr/local/", filename);
	p = concat_path_file(n, "/bin/");
	free(n);
	n = concat_path_file(p, filename);
	free(p);
	if (!access(n, X_OK) && !stat(n, &s) && S_ISREG(s.st_mode))
		return n;
	free(n);

	free(path);
	return NULL;
}

char *concat_path_file(const char *path, const char *filename) {
	char *lc;
	if (!path)
		path = "";
	if (path && *path) {
		size_t sz = strlen(path) - 1;
		if ((unsigned char)*(path + sz) == '/')
			lc = (char *)(path + sz);
		else
			lc = NULL;
	} else {
		lc = NULL;
	}
	while (*filename == '/')
		filename++;
	char *tmp;
	asprintf(&tmp, "%s%s%s", path, (lc == NULL ? "/" : ""), filename);
	return tmp;
}