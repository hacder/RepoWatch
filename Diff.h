#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// A class that I want to start using, but that isn't used at all right now, which contains information
// about a single changeset. Most of the information is contained in the files array.

@interface Diff : NSObject <NSTableViewDataSource>{
	NSString *hash;
	NSString *author;
	NSDate *ts;
	NSMutableArray *files; // Array of FileDiff objects
	NSMutableArray *backingStore;
}

- (void) addFile: (NSString *)fileName;
- (void) flip;
- (void) start;
- (int) numberOfRowsInTableView: (NSTableView *)tv;
- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)col row: (NSInteger)r;
- init;

@end