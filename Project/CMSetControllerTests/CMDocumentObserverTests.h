//
//  CMDocumentObserverTests.h
//  CMSetControllerTests
//
//  Created by Samuel Ford on 2/17/13.
//  Copyright (c) 2013 Samuel Ford. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface CMDocumentObserverTests : SenTestCase 

@property (strong) NSMutableArray *inserted;
@property (strong) NSMutableArray *removed;
@property (strong) NSMutableArray *modified;

@end
