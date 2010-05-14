#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoInstance.h"

// Lots of general helper functions. They were taking up too much room in other classes.

@interface RepoHelper : NSObject {
}

+ (NSString *)shortDiff: (RepoInstance *)repo;
+ (NSString *)stringFromFile: (NSFileHandle *)file;
+ (NSFileHandle *)pipeForTask: (NSTask *)t;
+ (NSFileHandle *)errForTask: (NSTask *)t;
+ (void)logTask: (NSTask *)task appending: (NSString *)appending;
+ (NSAttributedString *)colorizedDiffFromArray: (NSArray *)arr;
	
@end