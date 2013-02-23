//
//  CMDocumentObserverTests.m
//  CMSetControllerTests
//
//  Created by Samuel Ford on 2/17/13.
//  Copyright (c) 2013 Samuel Ford. All rights reserved.
//

#import "CMDocumentObserverTests.h"
#import "CMDocument.h"
#import "CMFriend.h"

static void * const kSetContext = (void *)@"com.causticmango.CMDocumentObserverTests.set";
static void * const kItemContext = (void *)@"com.causticmango.CMDocumentObserverTests.item";

@implementation CMDocumentObserverTests

@synthesize inserted;
@synthesize removed;
@synthesize modified;

- (void)setUp
{
    self.inserted = [NSMutableArray array];
    self.removed = [NSMutableArray array];
    self.modified = [NSMutableArray array];
}

/* 
 * These tests are less about testing CMDocument and more about testing the way we understand KVO to work over a set.
 * The asserts in these tests represent the expectations of the CMSetController implementation and are more like
 * "proving grounds" for the controller design.
 */

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSNumber *kind = [change objectForKey:NSKeyValueChangeKindKey];
    id new = [change objectForKey:NSKeyValueChangeNewKey];
    id old = [change objectForKey:NSKeyValueChangeOldKey];
    
    switch ([kind intValue]) {
        case NSKeyValueChangeInsertion:
            if (context == kSetContext) [self.inserted addObjectsFromArray:[(NSSet *)new allObjects]];
            else [self.inserted addObject:new];
            break;
        
        case NSKeyValueChangeRemoval:
            if (context == kSetContext) [self.removed addObjectsFromArray:[(NSSet *)old allObjects]];
            else [self.removed addObject:old];
            break;
            
        case NSKeyValueChangeSetting:
            [self.modified addObject:new];
            break;
            
        default:
            NSLog(@"unhandled change: %@", kind);
            break;
    }
    
    if ([new isKindOfClass:[NSSet class]]) {
        for (CMFriend *f in new) {
            [f addObserver:self forKeyPath:@"name"
                   options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                   context:kItemContext];
        }
    }
    
    if ([old isKindOfClass:[NSSet class]]) {
        for (CMFriend *f in old) {
            [f removeObserver:self forKeyPath:@"name"];
        }
    }
}

- (void)testCanObserveFriendsSetInsert
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    
    [doc addObserver:self forKeyPath:@"friends"
             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
             context:kSetContext];
    
    CMFriend *f = [[CMFriend alloc] init];
    f.name = @"Test 1";
    f.favoriteColor = @"Grey";
    f.rating = [NSNumber numberWithInt:1];
    
    // act
    
    [doc addFriendsObject:f];
    
    // assert
    
    [doc removeObserver:self forKeyPath:@"friends"];
    
    STAssertEquals((NSUInteger)1, self.inserted.count, @"wrong number of inserted objects: %d", self.inserted.count);
}

- (void)testCanObserveFriendsSetRemove
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];

    [doc addObserver:self 
          forKeyPath:@"friends"
             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
             context:kSetContext];
    
    CMFriend *f = [[CMFriend alloc] init];
    f.name = @"Test 1";
    f.favoriteColor = @"Grey";
    f.rating = [NSNumber numberWithInt:1];
    
    [doc addFriendsObject:f];

    // act
    
    [doc removeFriendsObject:f];
    
    // assert
    
    [doc removeObserver:self forKeyPath:@"friends"];

    STAssertEquals((NSUInteger)1, self.removed.count, @"wrong number of removed objects: %d", self.removed.count);
}

- (void)testCanObserveFriendUpdate
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    
    CMFriend *f = [[CMFriend alloc] init];
    f.name = @"Test 1";
    f.favoriteColor = @"Grey";
    f.rating = [NSNumber numberWithInt:1];
    
    [doc addObserver:self 
          forKeyPath:@"friends" 
             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
             context:kSetContext];
    
    [doc addFriendsObject:f];
    
    // act
    
    f.name = @"Test Updated";
    
    // assert
    
    [doc removeObserver:self forKeyPath:@"friends"];
    
    STAssertEquals((NSUInteger)1, self.inserted.count, @"wrong number of inserted objects: %d", self.inserted.count);
    STAssertEquals((NSUInteger)1, self.modified.count, @"wrong number of modifed objects: %d", self.modified.count);
}

- (void)testSetAssignIsObserved
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    
    CMFriend *f1 = [[CMFriend alloc] init];
    f1.name = @"Test 1";
    f1.favoriteColor = @"White";
    f1.rating = [NSNumber numberWithInt:1];
    
    CMFriend *f2 = [[CMFriend alloc] init];
    f2.name = @"Test 2";
    f2.favoriteColor = @"Black";
    f2.rating = [NSNumber numberWithInt:2];

    NSSet *s = [NSSet setWithObjects:f1, f2, nil];
    
    [doc addObserver:self
          forKeyPath:@"friends"
             options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
             context:kSetContext];
    
    // act
    
    [doc addFriends:s];
    
    // assert
    
    [doc removeObserver:self forKeyPath:@"friends"];

    STAssertEquals((NSUInteger)2, self.inserted.count, @"wrong number of inserted objects: %d", self.inserted.count);
}

@end
