//
//  CMDocument.h
//  CMSetController
//
//  Created by Samuel Ford on 2/17/13.
//  Copyright (c) 2013 Samuel Ford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CMFriend.h"

@interface CMDocument : NSObject 

@property (strong) NSString *name;
@property (readonly, copy) NSSet *friends;
@property (readonly, copy) NSMutableSet *mutableFriends;

- (void)addFriendsObject:(CMFriend *)friend;
- (void)removeFriendsObject:(CMFriend *)friend;
- (void)addFriends:(NSSet *)objects;
- (void)removeFriends:(NSSet *)objects;

@end