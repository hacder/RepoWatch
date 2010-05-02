#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class RepoInstance;

@interface RepoMenuItem : NSMenuItem {
	RepoInstance *repo;
	NSMenu *sub;
	NSDate *lastUpdate;
	NSLock *lock;

	NSDateFormatter *dateFormatter;
	NSDictionary *dateAttributes;
	NSDictionary *logAttributes;
}

- (id) initWithRepository: (RepoInstance *)repo;
- (RepoInstance *)repository;

@end