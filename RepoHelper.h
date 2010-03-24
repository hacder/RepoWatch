#import <Foundation/Foundation.h>

@interface RepoHelper : NSObject {
}

+ (NSString *)shortenDiff: (NSString *)diff;
+ (NSString *)stringFromFile: (NSFileHandle *)file;
+ (NSFileHandle *)pipeForTask: (NSTask *)t;
+ (NSFileHandle *)errForTask: (NSTask *)t;

@end