//
//  CMDocument.m
//  CMSetController
//
//  Created by Samuel Ford on 2/17/13.
//  Copyright (c) 2013 Samuel Ford. All rights reserved.
//

#import "CMDocument.h"
#import "CMFriend.h"

@implementation CMDocument {
    NSMutableSet *_friends;
}

@synthesize name = _name;

- (id)init 
{
    if ((self = [super init])) {
        _friends = [NSMutableSet set];
    }
    
    return self;
}

- (NSString *)description
{
    return _name;
}

- (NSSet *)friends
{
    return [NSSet setWithSet:_friends];
}

- (NSMutableSet *)mutableFriends
{
    return [self mutableSetValueForKey:@"friends"];
}

- (void)addFriendsObject:(CMFriend *)friend
{
    [_friends addObject:friend];
}

- (void)removeFriendsObject:(CMFriend *)friend
{
    [_friends removeObject:friend];
}

- (void)addFriends:(NSSet *)objects
{
    [_friends unionSet:objects];
}

- (void)removeFriends:(NSSet *)objects
{
    [_friends minusSet:objects];
}

@end
