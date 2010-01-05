#import "GitDiffButtonDelegate.h"

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

- (NSArray *)getUntracked {
	return [self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"ls-files", @"--others", @"--exclude-standard", nil] withName: @"Git::getUntracked::ls-files"];
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

- (void) commit: (id) menuItem {
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
	} else if (upstreamMod) {
		NSArray *arr = [NSArray arrayWithObjects: @"log", @"HEAD..origin", @"--abbrev-commit", @"--pretty=%h %s", nil];
		NSArray *resultarr = [self arrayFromResultOfArgs: arr withName: @"Git::commit::log"];
		
		[mc->butt setTitle: @"Update from upstream"];
		[mc->butt setTarget: self];
		[mc->butt setAction: @selector(upstreamUpdate:)];

		NSString *string = [resultarr objectAtIndex: 0];
		[mc->tv setString: string];
		[mc->tv setEditable: NO];
			
		arr = [NSArray arrayWithObjects: @"diff", @"HEAD..origin", nil];
		resultarr = [self arrayFromResultOfArgs: arr withName: @"Git::commit::diff"];
		string = [resultarr objectAtIndex: 0];
		[mc->diffView setString: string];
		[mc->diffView setEditable: NO];
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
	[self arrayFromResultOfArgs: [NSArray arrayWithObjects: @"commit", @"-a", @"-m", [[mc->tv textStorage] mutableString], nil] withName: @"Git::clickUpdate::commit"];
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
	localMod = NO;
	upstreamMod = NO;
	[dirtyLock lock];
	dirty = NO;
	[dirtyLock unlock];
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

	localMod = YES;
	upstreamMod = NO;
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
	
	NSString *remoteString = [self getDiffRemote: YES];
	NSString *string = [self getDiffRemote: NO];
	NSArray *untracked = [self getUntracked];
	if (untracked) {
		NSLog(@"Untracked in %@ is %@", repository, untracked);
		[GrowlApplicationBridge notifyWithTitle: @"Untracked Files" description: repository notificationName: @"testing" iconData: nil priority: 1.0 isSticky: NO clickContext: nil];
	}
	
	NSMenu *m = [[[NSMenu alloc] initWithTitle: @"Testing"] autorelease];

	the_index = [self doLogsForMenu: m atIndex: the_index];
	[m insertItem: [NSMenuItem separatorItem] atIndex: the_index++];

	if (!remoteString || [remoteString isEqual: @""]) {
		if (string == nil || [string isEqual: @""]) {
			[self noMods];
		} else {
			[self localModsWithMenu: m index: the_index string: string];
		}
	} else {
		// There is a remote diff.
		NSString *sTit;
		localMod = NO;
		upstreamMod = YES;
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
	[[m insertItemWithTitle: @"Open in Finder" action: @selector(openInFinder:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
	[[m insertItemWithTitle: @"Open in Terminal" action: @selector(openInTerminal:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];
	[[m insertItemWithTitle: @"Ignore" action: @selector(ignore:) keyEquivalent: @"" atIndex: the_index++] setTarget: self];

	dispatch_sync(dispatch_get_main_queue(), ^{
		if (localMod)
			[menuItem setOffStateImage: mc->redBubble];
		else if (upstreamMod)
			[menuItem setOffStateImage: mc->yellowBubble];
		else
			[menuItem setOffStateImage: mc->greenBubble];
		[menuItem setSubmenu: m];
	});
}

@end