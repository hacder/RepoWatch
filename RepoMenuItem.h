#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "RepoButtonDelegate.h"

@interface RepoMenuItem : NSMenuItem {
	RepoButtonDelegate *repo;
	NSMenu *sub;
	NSDate *lastUpdate;
}

- (id) initWithRepository: (RepoButtonDelegate *)repo;

@end