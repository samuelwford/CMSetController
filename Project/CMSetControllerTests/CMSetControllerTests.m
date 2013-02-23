//
//  CMSetControllerTests.m
//  CMSetControllerTests
//
//  Created by Samuel Ford on 2/17/13.
//  Copyright (c) 2013 Samuel Ford. All rights reserved.
//

#import "CMSetControllerTests.h"
#import "CMDocument.h"
#import "CMFriend.h"

@implementation CMSetControllerTests {
    NSInteger willChangeCalls;
    NSInteger didChangeCalls;
    
    NSMutableSet *set;
    NSMutableArray *changes;
    NSMutableArray *sectionChanges;
}

- (void)setUp
{
    [super setUp];
    
    set = [NSMutableSet set];
    
    willChangeCalls = 0;
    didChangeCalls = 0;
    
    changes = [NSMutableArray array];
    sectionChanges = [NSMutableArray array];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

#pragma mark - Delegate Implementation

- (void)controller:(CMSetController *)controller didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(CMSetControllerChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    NSArray *values = [NSArray arrayWithObjects:object, [NSNumber numberWithInt:type], indexPath ? indexPath : [NSNull null], newIndexPath ? newIndexPath : [NSNull null], nil];
    NSArray *keys = [NSArray arrayWithObjects:@"object", @"type", @"indexPath", @"newIndexPath", nil];
    
    NSDictionary *change = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    [changes addObject:change];
}

- (void)controller:(CMSetController *)controller didChangeSection:(id<CMSetControllerSectionInfo>)sectionInfo atIndex:(NSUInteger)index forChangeType:(CMSetControllerChangeType)type
{
    NSArray *values = [NSArray arrayWithObjects:[sectionInfo name], [NSNumber numberWithInt:type], [NSNumber numberWithInt:index], nil];
    NSArray *keys = [NSArray arrayWithObjects:@"section", @"type", @"index", nil];
    
    NSDictionary *change = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    
    [sectionChanges addObject:change];
}

- (void)controllerWillChangeContent:(CMSetController *)controller
{
    willChangeCalls++;
}

- (void)controllerDidChangeContent:(CMSetController *)controller
{
    didChangeCalls++;
}

#pragma mark - Basic Sanity Checks

- (void)testCanBeCreated
{
    CMSetController *c = [[CMSetController alloc] initWithObserved:nil
                                                        setKeyPath:nil
                                                          keyPaths:[NSArray array]
                                                sectionNameKeyPath:nil
                                                   sortDescriptors:nil
                                                          delegate:nil];
    
    STAssertNotNil(c, @"check the speed of light ...");
}

- (void)testCanFailConsistencyCheck
{
    // arrange
    
    CMSetController *c = [[CMSetController alloc] init];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    // assert
    
    NSLog(@"error: %@", error);
    STAssertFalse(result, @"query should have failed");
    
    // clean up
    
    [c stopObserving];
}

- (void)testCanPassConsistencyCheck
{
    // arrange
    
    CMSetController *c = [[CMSetController alloc] initWithObserved:self
                                                        setKeyPath:@"set"
                                                          keyPaths:[NSArray arrayWithObject:@"foo"]
                                                sectionNameKeyPath:nil
                                                   sortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES]]
                                                          delegate:self];
    
    // act
    
    NSError *error;
    BOOL r = [c performQuery:&error];
    
    // assert
    
    STAssertTrue(r, @"error: %@", error);
    
    // clean up
    
    [c stopObserving];
}

#pragma mark - Query Tests

- (void)testEmptySetQueryHasOneSectionAndNoRows
{
    // arrange
    
    CMSetController *c = [[CMSetController alloc] initWithObserved:self
                                                        setKeyPath:@"set"
                                                          keyPaths:[NSArray arrayWithObject:@"foo"]
                                                sectionNameKeyPath:nil
                                                   sortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES]]
                                                          delegate:self];
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)1, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)0, si.numberOfObjects, @"wrong number of rows");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithOneItemHasOneSectionAndOneRow
{
    // arrange
    
    CMSetController *c = [[CMSetController alloc] initWithObserved:self
                                                        setKeyPath:@"set"
                                                          keyPaths:[NSArray arrayWithObject:@"foo"]
                                                sectionNameKeyPath:nil
                                                   sortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES]]
                                                          delegate:self];
    
    set = [NSSet setWithObject:@"one"];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)1, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)1, si.numberOfObjects, @"wrong number of rows");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithThreeItemsHasOneSectionAndThreeRowsProperlySorted
{
    // arrange
    
    CMSetController *c = [[CMSetController alloc] initWithObserved:self
                                                        setKeyPath:@"set"
                                                          keyPaths:[NSArray arrayWithObject:@"description"]
                                                sectionNameKeyPath:nil
                                                   sortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES]]
                                                          delegate:self];
    
    set = [NSSet setWithObjects:@"one", @"two", @"three", nil];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)1, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)3, si.numberOfObjects, @"wrong number of rows");
    
    STAssertEqualObjects(@"one", [[si objects] objectAtIndex:0], @"sections isn't sorted right");
    STAssertEqualObjects(@"three", [[si objects] objectAtIndex:1], @"sections isn't sorted right");
    STAssertEqualObjects(@"two", [[si objects] objectAtIndex:2], @"sections isn't sorted right");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithThreeItemsHasTwoSections
{
    // arrange
    
    CMSetController *c = [[CMSetController alloc] initWithObserved:self
                                                        setKeyPath:@"set"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    set = [NSSet setWithObjects:
           [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]],
           [CMFriend friendWithName:@"sue" favoriteColor:@"blue" rating:[NSNumber numberWithInt:2]],
           [CMFriend friendWithName:@"ben" favoriteColor:@"red" rating:[NSNumber numberWithInt:3]],
           nil];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)2, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals(@"blue", [si name], @"first section name is wrong");
    STAssertEquals((NSUInteger)1, [si numberOfObjects], @"first section has wrong number of items");
    
    si = [c.sections objectAtIndex:1];
    STAssertEquals(@"red", [si name], @"second section name is wrong");
    STAssertEquals((NSUInteger)2, [si numberOfObjects], @"second section has wrong number of items");
    
    // clean up
    
    [c stopObserving];
}

#pragma mark - Add & Remove Tests

- (void)testSetWithOneSectionHasOneMoreItemAfterAdd
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    [doc addFriends:[NSMutableSet setWithObjects:
                     [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]],
                     [CMFriend friendWithName:@"sue" favoriteColor:@"red" rating:[NSNumber numberWithInt:2]],
                     [CMFriend friendWithName:@"ben" favoriteColor:@"red" rating:[NSNumber numberWithInt:3]],
                     nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    [doc addFriendsObject:[CMFriend friendWithName:@"sally" favoriteColor:@"red" rating:[NSNumber numberWithInt:4]]];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)1, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)4, si.numberOfObjects, @"wrong number of rows");
    
    id sally = [[si objects] objectAtIndex:2];
    STAssertEqualObjects(@"sally", [sally name], @"sally should be the third object");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithOneSectionHasOneMoreItemAfterAddAtTheBeginning
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    [doc addFriends:[NSMutableSet setWithObjects:
                     [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]],
                     [CMFriend friendWithName:@"sue" favoriteColor:@"red" rating:[NSNumber numberWithInt:2]],
                     [CMFriend friendWithName:@"ben" favoriteColor:@"red" rating:[NSNumber numberWithInt:3]],
                     nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    [doc addFriendsObject:[CMFriend friendWithName:@"alex" favoriteColor:@"red" rating:[NSNumber numberWithInt:4]]];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)1, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)4, si.numberOfObjects, @"wrong number of rows");
    
    id alex = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"alex", [alex name], @"alex should be the third object");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithOneSectionHasOneMoreItemAfterAddAtTheEnd
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    [doc addFriends:[NSMutableSet setWithObjects:
                     [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]],
                     [CMFriend friendWithName:@"sue" favoriteColor:@"red" rating:[NSNumber numberWithInt:2]],
                     [CMFriend friendWithName:@"ben" favoriteColor:@"red" rating:[NSNumber numberWithInt:3]],
                     nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    [doc addFriendsObject:[CMFriend friendWithName:@"zoe" favoriteColor:@"red" rating:[NSNumber numberWithInt:4]]];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)1, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)4, si.numberOfObjects, @"wrong number of rows");
    
    id zoe = [[si objects] lastObject];
    STAssertEqualObjects(@"zoe", [zoe name], @"zoe should be the third object");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithOneSectionHasTwoAfterInsert
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    [doc addFriends:[NSMutableSet setWithObjects:
                     [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]],
                     [CMFriend friendWithName:@"sue" favoriteColor:@"red" rating:[NSNumber numberWithInt:2]],
                     [CMFriend friendWithName:@"ben" favoriteColor:@"red" rating:[NSNumber numberWithInt:3]],
                     nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    [doc addFriendsObject:[CMFriend friendWithName:@"zoe" favoriteColor:@"blue" rating:[NSNumber numberWithInt:4]]];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)2, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)1, si.numberOfObjects, @"wrong number of rows new new section");
    
    id zoe = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"zoe", [zoe name], @"zoe should be the first object in the first section");
    
    si = [c.sections objectAtIndex:1];
    STAssertEquals((NSUInteger)3, si.numberOfObjects, @"wrong number of rows in original section");
    
    id ben = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"ben", [ben name], @"ben should be the first object in the original section");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithOneSectionHasTwoAfterInsertAsTheLastSection
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    [doc addFriends:[NSMutableSet setWithObjects:
                     [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]],
                     [CMFriend friendWithName:@"sue" favoriteColor:@"red" rating:[NSNumber numberWithInt:2]],
                     [CMFriend friendWithName:@"ben" favoriteColor:@"red" rating:[NSNumber numberWithInt:3]],
                     nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    [doc addFriendsObject:[CMFriend friendWithName:@"alex" favoriteColor:@"yellow" rating:[NSNumber numberWithInt:4]]];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)2, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:1];
    STAssertEquals((NSUInteger)1, si.numberOfObjects, @"wrong number of rows new new section");
    
    id alex = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"alex", [alex name], @"alex should be the first object in the second section");
    
    si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)3, si.numberOfObjects, @"wrong number of rows in original section");
    
    id ben = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"ben", [ben name], @"ben should be the first object in the original section");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithTwoSectionHasThreeAfterInsertAsTheMiddleSection
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    [doc addFriends:[NSMutableSet setWithObjects:
                     [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]],
                     [CMFriend friendWithName:@"sue" favoriteColor:@"yellow" rating:[NSNumber numberWithInt:2]],
                     [CMFriend friendWithName:@"ben" favoriteColor:@"red" rating:[NSNumber numberWithInt:3]],
                     nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    [doc addFriendsObject:[CMFriend friendWithName:@"alex" favoriteColor:@"teal" rating:[NSNumber numberWithInt:4]]];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)3, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:1];
    STAssertEquals((NSUInteger)1, si.numberOfObjects, @"wrong number of rows new new section");
    
    id alex = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"alex", [alex name], @"alex should be the first object in the second section");
    
    si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)2, si.numberOfObjects, @"wrong number of rows in original first section");
    
    id ben = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"ben", [ben name], @"ben should be the first object in the original first section");
    
    si = [c.sections lastObject];
    STAssertEquals((NSUInteger)1, si.numberOfObjects, @"wrong number of rows in the original last section");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithOneSectionHasOneLessAfterRemove
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    [doc addFriends:[NSMutableSet setWithObjects:
                     [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]],
                     [CMFriend friendWithName:@"sue" favoriteColor:@"red" rating:[NSNumber numberWithInt:2]],
                     [CMFriend friendWithName:@"ben" favoriteColor:@"red" rating:[NSNumber numberWithInt:3]],
                     nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    CMFriend *friend = [[[c.sections objectAtIndex:0] objects] objectAtIndex:0];
    [doc removeFriendsObject:friend];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)1, c.sections.count, @"wrong number of sections");
    
    STAssertEqualObjects(@"ben", [friend name], @"ben should be the friend we removed");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)2, si.numberOfObjects, @"wrong number of rows in original first section");
    
    id joe = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"joe", [joe name], @"joe should be the first object in the original first section");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithOneItemOneSectionAndNoRowsAfterRemove
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    CMFriend *friend = [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]];
    [doc addFriendsObject:friend];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    [doc removeFriendsObject:friend];
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)0, c.sections.count, @"wrong number of sections");
    
    // clean up
    
    [c stopObserving];
}

#pragma mark - Change Tests

- (void)testSetWithTwoItemsInOneSectionHasReverseOrderAfterChange
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    
    CMFriend *joe = [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]];
    CMFriend *sue = [CMFriend friendWithName:@"sue" favoriteColor:@"red" rating:[NSNumber numberWithInt:2]];
    
    [doc addFriends:[NSMutableSet setWithObjects:joe, sue, nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    joe.name = @"zoe";
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)1, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)2, si.numberOfObjects, @"wrong number of rows in original first section");
    
    sue = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"sue", [sue name], @"sue should be the first object in the original first section");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithTwoItemsInOneSectionHasTwoSectionsWithOneItemAfterChange
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    
    CMFriend *joe = [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]];
    CMFriend *sue = [CMFriend friendWithName:@"sue" favoriteColor:@"red" rating:[NSNumber numberWithInt:2]];
    
    [doc addFriends:[NSMutableSet setWithObjects:joe, sue, nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    joe.favoriteColor = @"yellow";
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)2, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)1, si.numberOfObjects, @"wrong number of rows in original first section");
    
    sue = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"sue", [sue name], @"sue should be the first object in the original first section");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithTwoItemsInOneSectionHasTwoSectionsWithOneItemAfterChangeReversed
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    
    CMFriend *joe = [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]];
    CMFriend *sue = [CMFriend friendWithName:@"sue" favoriteColor:@"red" rating:[NSNumber numberWithInt:2]];
    
    [doc addFriends:[NSMutableSet setWithObjects:joe, sue, nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    sue.favoriteColor = @"blue";
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)2, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)1, si.numberOfObjects, @"wrong number of rows in original first section");
    
    sue = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"sue", [sue name], @"sue should be the first object in the new first section");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithTwoItemsInOneSectionHasOneNewSectionsAfterChange
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    
    CMFriend *joe = [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]];
    CMFriend *sue = [CMFriend friendWithName:@"sue" favoriteColor:@"red" rating:[NSNumber numberWithInt:2]];
    
    [doc addFriends:[NSMutableSet setWithObjects:joe, sue, nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    joe.favoriteColor = @"yellow";
    sue.favoriteColor = @"yellow";
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)1, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)2, si.numberOfObjects, @"wrong number of rows in original first section");
    
    sue = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"joe", [joe name], @"joe should be the first object in the new first section");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithThreeItemsInThreeSectionsHasOneNewSectionsAfterChange
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    
    CMFriend *joe = [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]];
    CMFriend *sue = [CMFriend friendWithName:@"sue" favoriteColor:@"orange" rating:[NSNumber numberWithInt:2]];
    CMFriend *alice = [CMFriend friendWithName:@"alice" favoriteColor:@"green" rating:[NSNumber numberWithInt:3]];
    
    [doc addFriends:[NSMutableSet setWithObjects:joe, sue, alice, nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    joe.favoriteColor = @"yellow";
    sue.favoriteColor = @"yellow";
    alice.favoriteColor = @"yellow";
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)1, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:0];
    STAssertEquals((NSUInteger)3, si.numberOfObjects, @"wrong number of rows in original first section");
    
    alice = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"alice", [alice name], @"alice should be the first object in the new first section");
    
    STAssertEquals(willChangeCalls, didChangeCalls, @"unbalanced calls to will/did change");
    STAssertTrue(willChangeCalls > 0, @"didn't get any change calls");
    
    STAssertEquals((NSUInteger)3, changes.count, @"wrong number of chagnes");
    STAssertEquals((NSUInteger)4, sectionChanges.count, @"wrong number of section changes");
    
    // clean up
    
    [c stopObserving];
}

- (void)testSetWithThreeItemsInThreeSectionsHasOneNewMiddleSectionAfterChange
{
    // arrange
    
    CMDocument *doc = [[CMDocument alloc] init];
    CMSetController *c = [[CMSetController alloc] initWithObserved:doc
                                                        setKeyPath:@"friends"
                                                          keyPaths:[NSArray arrayWithObjects:@"name", @"favoriteColor", nil]
                                                sectionNameKeyPath:@"favoriteColor"
                                                   sortDescriptors:[NSArray arrayWithObjects:[NSSortDescriptor sortDescriptorWithKey:@"favoriteColor" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES], nil]
                                                          delegate:self];
    
    
    CMFriend *joe = [CMFriend friendWithName:@"joe" favoriteColor:@"red" rating:[NSNumber numberWithInt:1]];
    CMFriend *sue = [CMFriend friendWithName:@"sue" favoriteColor:@"orange" rating:[NSNumber numberWithInt:2]];
    CMFriend *alice = [CMFriend friendWithName:@"alice" favoriteColor:@"green" rating:[NSNumber numberWithInt:3]];
    
    [doc addFriends:[NSMutableSet setWithObjects:joe, sue, alice, nil]];
    
    // act
    
    NSError *error;
    BOOL result = [c performQuery:&error];
    
    NSLog(@"%@", c.sections);
    
    sue.favoriteColor = @"pink";
    
    NSLog(@"%@", c.sections);
    
    // assert
    
    STAssertTrue(result, @"query failed: %@", error);
    
    STAssertEquals((NSUInteger)3, c.sections.count, @"wrong number of sections");
    
    id<CMSetControllerSectionInfo> si = [c.sections objectAtIndex:1];
    STAssertEquals((NSUInteger)1, si.numberOfObjects, @"wrong number of rows in middle section");
    STAssertEqualObjects(@"pink", [si name], @"middle section should have flipped from orange to pink");
    
    sue = [[si objects] objectAtIndex:0];
    STAssertEqualObjects(@"sue", [sue name], @"alice should be the first object in the new first section");
    
    STAssertEquals(willChangeCalls, didChangeCalls, @"unbalanced calls to will/did change");
    STAssertTrue(willChangeCalls > 0, @"didn't get any change calls");
    
    STAssertEquals((NSUInteger)1, changes.count, @"wrong number of chagnes");
    STAssertEquals((NSUInteger)2, sectionChanges.count, @"wrong number of section changes");
    
    // clean up
    
    [c stopObserving];
}

@end
