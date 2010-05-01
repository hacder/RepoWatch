#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// Scans directories for repositories. Also responsible for finding the executables
// for git and mercurial (this responsibility needs to go elsewhere).

@interface Scanner : NSObject {
	NSLock *lock;
}

- (void) findSupportedSCMS;
- (void) searchAllPaths;
- (void) searchPath: (NSString *)path;
- (BOOL) testDirectoryContents: (NSArray *)contents ofPath: (NSString *)path;
- (void) openFile: (NSString *)filename withContents: (NSArray *)contents;

@end