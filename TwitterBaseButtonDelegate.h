#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ButtonDelegate.h"

@interface TwitterBaseButtonDelegate : ButtonDelegate {
}

- (NSString *) base64Username: (NSString *)u password: (NSString *)p;
- (NSData *)fetchDataForURL: (NSURL *)url;

@end