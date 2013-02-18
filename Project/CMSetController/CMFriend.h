//
//  CMFriend.h
//  CMSetController
//
//  Created by Samuel Ford on 2/17/13.
//  Copyright (c) 2013 Samuel Ford. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMFriend : NSObject

@property (strong) NSString *name;
@property (strong) NSString *favoriteColor;
@property (strong) NSNumber *rating;

+ (CMFriend *)friendWithName:(NSString *)name favoriteColor:(NSString *)color rating:(NSNumber *)rating;

@end
