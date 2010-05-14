#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoInstance.h"

@interface CommitWindowController : NSObject <NSTableViewDataSource> {
	IBOutlet NSWindow *commitWindow;
	IBOutlet NSTableView *changedFilesTable;
	RepoInstance *currentRepo;
}

@end