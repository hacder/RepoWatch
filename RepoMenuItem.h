#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

@interface RepoMenuItem : NSMenuItem {
	RepoButtonDelegate *repo;
	NSMenu *sub;
	NSDate *lastUpdate;
	NSLock *lock;
}

- (id) initWithRepository: (RepoButtonDelegate *)repo;

@end