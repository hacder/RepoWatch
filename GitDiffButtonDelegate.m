#import "GitDiffButtonDelegate.h"
#import "BubbleFactory.h"

@implementation GitDiffButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m statusItem: (NSStatusItem *)si mainController: (MainController *)mcc gitPath: (char *)gitPath repository: (NSString *)rep {
	self = [super initWithTitle: s menu: m statusItem: si mainController: mcc repository: rep];
	git = gitPath;
	[menuItem setHidden: YES];
	[menuItem setAction: nil];
	
	diffCommitTV = mc->diffCommitTextView;
	[diffCommitTV retain];
	
	[self fire: nil];
	[self updateRemote];
	return self;
}

- (void) addAll: (id) button {
	int i;
	for (i = 0; i < [currentUntracked count]; i++) {
		[self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"add", [currentUntracked objectAtIndex: i], nil]
			withName: @"git::addAll::add"];
	}
	[mc->untrackedWindow close];
	[self fire: nil];
}

- (void) ignoreAll: (id) button {
	NSString *path = [NSString stringWithFormat: @"%@/%@", repository, @".gitignore"];
	NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath: path];
	if (fh == nil) {
		[@".gitignore\n" writeToFile: path atomically: NO encoding: NSASCIIStringEncoding error: nil];
		fh = [NSFileHandle fileHandleForWritingAtPath: path];
		if (fh == nil)
			return;
	}
	[fh truncateFileAtOffset: [fh seekToEndOfFile]];
	int i;
	for (i = 0; i < [currentUntracked count]; i++) {
		NSString *fileName = [currentUntracked objectAtIndex: i];
		[fh writeData: [fileName dataUsingEncoding: NSUTF8StringEncoding]];
		[fh writeData: [@"\n" dataUsingEncoding: NSASCIIStringEncoding]];
	}
	[fh synchronizeFile];
	[fh closeFile];
	[mc->untrackedWindow close];
	[self fire: nil];
}

- (NSArray *)getUntracked {
	NSArray *arr = [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"ls-files", @"--others", @"--exclude-standard", @"-z", nil]
		withName: @"Git::getUntracked::ls-files"];
	NSMutableArray *arrmut = [NSMutableArray arrayWithArray: arr];
	int i;
	for (i = 0; i < [arrmut count]; i++) {
		NSMutableString *original = [NSMutableString stringWithString: [arrmut objectAtIndex: i]];
		if ([original characterAtIndex: 0] == '"' && [original characterAtIndex: [original length] - 1] == '"') {
			[original deleteCharactersInRange: NSMakeRange(0, 1)];
			[original deleteCharactersInRange: NSMakeRange([original length] - 1, 1)];
		}
	}
	return arrmut;
}

- (NSTask *)taskFromArguments: (NSArray *)args {
	NSString *lp = [NSString stringWithFormat: @"%s", git];
	return [self baseTask: lp fromArguments: args];
}

- (void) updateRemote {
	NSString *string;
	NSArray *arr;
	
	arr = [NSArray arrayWithObjects: @"remote", nil];
	NSArray *resarr = [self arrayFromResultOfArgs: arr withName: @"Git::updateRemote::remote"];
	if (![resarr count])
		return;
	string = [resarr objectAtIndex: 0];
	string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (![string length])
		return;
	
	NSLog(@"Updating remote for %@", repository);
	
	[self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"fetch", nil] withName: @"Git::updateRemote::fetch"];
}
	
- (NSString *) getDiffRemote: (BOOL)remote {
	NSArray *arr; 
	NSArray *resultarr; 
	NSString *string;
	
	if (remote) {
		if (!lastRemote) {
			lastRemote = [NSDate date];
			[lastRemote retain];
		} else {
			if ([lastRemote timeIntervalSinceNow] > 3600) {
				[lastRemote release];
				lastRemote = [NSDate date];
				[lastRemote retain];
			} else {
				NSLog(@"Short circuiting diff remote, not enough time has passed.");
				return nil;
			}
		}
		NSLog(@"Actually running get diff remote.");
		arr = [NSArray arrayWithObjects: @"remote", nil];
		resultarr = [self arrayFromResultOfArgs: arr withName: @"Git::getDiffRemote::remote"];
		if (![resultarr count]) {
			upstreamMod = NO;
			return nil;
		}
		string = [resultarr objectAtIndex: 0];
		string = [string stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (![string length]) {
			upstreamMod = NO;
			return nil;
		}
		string = [NSString stringWithFormat: @"HEAD...%@", string];
		arr = [NSArray arrayWithObjects: @"diff", @"--shortstat", string, nil];
	} else {
		arr = [NSArray arrayWithObjects: @"diff", @"--shortstat", nil];
	}
	resultarr = [self arrayFromResultOfArgs: arr withName: @"Git::getDiffRemote::diff"];
	if (![resultarr count]) {
		upstreamMod = NO;
		return nil;
	}
	string = [resultarr objectAtIndex: 0];
	return [self shortenDiff: string];
}

- (void) pull: (id) menuItem {
	[mc->commitWindow setTitle: repository];
	[mc->commitWindow makeFirstResponder: mc->tv];

	NSArray *arr = [NSArray arrayWithObjects: @"log", @"HEAD..origin", @"--abbrev-commit", @"--pretty=%h %s", nil];
	NSArray *resultarr = [self arrayFromResultOfArgs: arr withName: @"Git::commit::log"];
	
	[mc->butt setTitle: @"Update from upstream"];
	[mc->butt setTarget: self];
	[mc->butt setAction: @selector(upstreamUpdate:)];

	NSString *string = [resultarr componentsJoinedByString: @"\n"];
	[mc->tv setString: string];
	[mc->tv setEditable: NO];
		
	arr = [NSArray arrayWithObjects: @"diff", @"HEAD..origin", nil];
	resultarr = [self arrayFromResultOfArgs: arr withName: @"Git::commit::diff"];
	string = [resultarr componentsJoinedByString: @"\n"];
	[mc->diffView setString: string];
	[mc->diffView setEditable: NO];

	[mc->commitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->commitWindow makeKeyAndOrderFront: NSApp];
}

- (void) commit: (id) menuItem {
	if (!localMod)
		return;
		
	[mc->commitWindow setTitle: repository];
	[mc->commitWindow makeFirstResponder: mc->tv];

	if (localMod) {	
		[mc->tv setEditable: YES];
		NSString *diffString = [self getDiff];
		[mc->tv setString: @""];
		[mc->diffView setString: diffString];
		[mc->butt setTitle: @"Do Commit"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(clickUpdate:)];
	}
	[mc->commitWindow center];
	[NSApp activateIgnoringOtherApps: YES];
	[mc->commitWindow makeKeyAndOrderFront: NSApp];
	[mc->commitWindow makeFirstResponder: mc->tv];
}

- (void) upstreamUpdate: (id) sender {
	[sender setEnabled: NO];
	[self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"rebase", @"origin", nil] withName: @"Git::upstreamUpdate::rebase"];
	[NSApp hide: self];
	[mc->commitWindow close];
	[sender setEnabled: YES];
	[self fire: nil];
}

- (void) clickUpdate: (id) button {
	[self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"commit", @"-a", @"-m", [[mc->tv textStorage] mutableString], nil]
		withName: @"Git::clickUpdate::commit"];
	[NSApp hide: self];
	[mc->commitWindow close];
	[self fire: nil];
}

- (int) doLogsForMenu: (NSMenu *)m atIndex: (int)the_index {
	int i;
	
	NSArray *logs = [self
			arrayFromResultOfArgs: [NSArray arrayWithObjects: @"log", @"-n", @"10", @"--pretty=format:%h %ar %s", @"--abbrev-commit", nil]
			withName: @"Git::doLogsForMenu::logs"];
	NSFont *firstFont = [NSFont userFixedPitchFontOfSize: 16.0];
	NSFont *secondFont = [NSFont userFixedPitchFontOfSize: 12.0];
	NSMenuItem *mi;

	if ([logs count] == 1 && [[logs objectAtIndex: 0] isEqualToString: @""]) {
		NSLog(@"%@: Thinks that there is no log: %@", repository, logs);
		mi = [[NSMenuItem alloc] initWithTitle: @"No history for this project" action: nil keyEquivalent: @""];
		[m addItem: mi];
		the_index++;
	} else {
		for (i = 0; i < [logs count]; i++) {
			NSString *tmp = [logs objectAtIndex: i];
			NSDictionary *attributes;
			if (i == 0) {
				attributes = [NSDictionary dictionaryWithObject: firstFont forKey: NSFontAttributeName];
			} else {
				attributes = [NSDictionary dictionaryWithObject: secondFont forKey: NSFontAttributeName];
			}
			NSAttributedString *attr = [[[NSAttributedString alloc] initWithString: tmp attributes: attributes] autorelease];
			if (tmp && [tmp length] > 0) {
				mi = [[NSMenuItem alloc] initWithTitle: tmp action: nil keyEquivalent: @""];
				[mi setAttributedTitle: attr];
				[mi autorelease];
				[m addItem: mi];
				the_index++;
			}
		}
	}
	
	return the_index;
}

- (void) noMods {
	dispatch_sync(dispatch_get_main_queue(), ^{
		NSString *s3;
		if (currentBranch == nil || [currentBranch isEqual: @"master"]) {
			s3 = [NSString stringWithFormat: @"%@",
				[repository lastPathComponent]];
		} else {
			s3 = [NSString stringWithFormat: @"%@ (%@)",
					[repository lastPathComponent], currentBranch];
		}
		[self setTitle: s3];
		[self setShortTitle: s3];
		[menuItem setHidden: NO];
	});
}

- (void) localModsWithMenu: (NSMenu *)m index: (int)the_index string: (NSString *)string {
	NSString *sTit;
	[GrowlApplicationBridge notifyWithTitle: @"Local Modifications" description: repository notificationName: @"testing" iconData: nil priority: 1.0 isSticky: NO clickContext: nil];

	[[m insertItemWithTitle: @"Commit these changes" action: @selector(commit:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
	if (currentBranch == nil || [currentBranch isEqual: @"master"]) {
		sTit = [NSString stringWithFormat: @"%@: %@",
			[repository lastPathComponent],
			[string stringByTrimmingCharactersInSet:
				[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	} else {
		sTit = [NSString stringWithFormat: @"%@: %@ (%@)",
			[repository lastPathComponent],
			[string stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]], currentBranch];
	}
	dispatch_sync(dispatch_get_main_queue(), ^{
		[self setTitle: sTit];
		[self setShortTitle: sTit];
		[menuItem setHidden: NO];
	});
}

- (void) realFire {
	int the_index = 0;
	
	[dirtyLock lock];
	dirty = NO;
	[dirtyLock unlock];
	
	NSString *remoteString = [self getDiffRemote: YES];
	NSString *string = [self getDiffRemote: NO];
	NSArray *untracked = [self getUntracked];

	if (untracked && [untracked count])
		untrackedFiles = YES;
	else
		untrackedFiles = NO;
	
	if (!remoteString || [remoteString isEqual: @""])
		upstreamMod = NO;
	else
		upstreamMod = YES;
		
	if (string == nil || [string isEqual: @""])
		localMod = NO;
	else
		localMod = YES;
			

	if (untrackedFiles) {
		NSLog(@"Untracked in %@ is %@", repository, untracked);
		[GrowlApplicationBridge notifyWithTitle: @"Untracked Files" description: [NSString stringWithFormat: @"%d untracked files in %@", [untracked count], repository] notificationName: @"testing" iconData: nil priority: 1.0 isSticky: NO clickContext: nil];
	}
	
	NSMenu *m = [[[NSMenu alloc] initWithTitle: @"Testing"] autorelease];

	the_index = [self doLogsForMenu: m atIndex: the_index];
	[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];

	if (untrackedFiles) {
		NSString *s = [NSString stringWithFormat: @"%@: %d untracked files", [repository lastPathComponent], [untracked count]];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setTitle: s];
			[self setShortTitle: s];
			[menuItem setHidden: NO];
		});
	} else if (!upstreamMod) {
		if (!localMod) {
			[self noMods];
		} else {
			[self localModsWithMenu: m index: the_index string: string];
		}
	} else {
		// There is a remote diff.
		NSString *sTit;
		[GrowlApplicationBridge notifyWithTitle: @"Upstream Modification" description: repository notificationName: @"testing" iconData: nil priority: 1.0 isSticky: NO clickContext: nil];

		[[m insertItemWithTitle: @"Update from origin" action: @selector(commit:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
		sTit = [NSString stringWithFormat: @"%@: %@",
			[repository lastPathComponent],
			[remoteString stringByTrimmingCharactersInSet:
				[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self setTitle: sTit];
			[self setShortTitle: sTit];
			[menuItem setHidden: NO];
		});
	}
	if (localMod)
		[[m insertItemWithTitle: @"Commit" action: @selector(commit:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
	if (untrackedFiles)
		[[m insertItemWithTitle: @"Untracked Files" action: @selector(dealWithUntracked:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
	[[m insertItemWithTitle: @"Open in Finder" action: @selector(openInFinder:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
	[[m insertItemWithTitle: @"Open in Terminal" action: @selector(openInTerminal:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
	[[m insertItemWithTitle: @"Ignore" action: @selector(ignore:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];

	dispatch_sync(dispatch_get_main_queue(), ^{
		if (untrackedFiles)
			[menuItem setOffStateImage: [BubbleFactory getBlueOfSize: 15]];
		else if (localMod)
			[menuItem setOffStateImage: [BubbleFactory getRedOfSize: 15]];
		else if (upstreamMod)
			[menuItem setOffStateImage: [BubbleFactory getYellowOfSize: 15]];
		else
			[menuItem setOffStateImage: [BubbleFactory getGreenOfSize: 15]];
		[menuItem setSubmenu: m];
	});
}

@end