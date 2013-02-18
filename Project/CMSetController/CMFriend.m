//
//  CMFriend.m
//  CMSetController
//
//  Created by Samuel Ford on 2/17/13.
//  Copyright (c) 2013 Samuel Ford. All rights reserved.
//

#import "CMFriend.h"

@implementation CMFriend

@synthesize name = _name;
@synthesize favoriteColor = _favoriteColor;
@synthesize rating = _rating;

+ (CMFriend *)friendWithName:(NSString *)name favoriteColor:(NSString *)color rating:(NSNumber *)rating
{
    CMFriend *friend = [[CMFriend alloc] init];
    friend.name = name;
    friend.favoriteColor = color;
    friend.rating = rating;
    
    return friend;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@) likes %@", _name, _rating, _favoriteColor];
}

@end
