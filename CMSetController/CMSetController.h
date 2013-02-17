//
//  CMSetController.h
//
//  Created by Samuel Ford on 4/6/12.
//  Copyright (c) Samuel Ford. All rights reserved.
//
//  https://github.com/causticmango/CMSetController
//

#import <Foundation/Foundation.h>

@protocol CMSetControllerDelegate;

@interface CMSetController : NSObject {
}

@property (nonatomic, readonly) id observed;
@property (nonatomic, readonly) NSString *setKeyPath;
@property (nonatomic, strong) NSString *sectionNameKeyPath;
@property (nonatomic, strong) NSArray *observedKeyPaths;
@property (nonatomic, strong) NSArray *sortDescriptors;
@property (nonatomic, weak) id<CMSetControllerDelegate> delegate;

@property (nonatomic, readonly) NSArray *sections;

- (id)initWithObserved:(id)observed setKeyPath:(NSString *)setKeyPath keyPaths:(NSArray *)keyPaths sectionNameKeyPath:(NSString *)sectionNameKeyPath sortDescriptors:(NSArray *)descriptors delegate:(id<CMSetControllerDelegate>)delegate;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForObject:(id)object;

- (BOOL)performQuery:(NSError **)error;
- (void)stopObserving;

@end

@protocol CMSetControllerSectionInfo <NSObject>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSUInteger numberOfObjects;
@property (nonatomic, readonly) NSArray *objects;

@end

@protocol CMSetControllerDelegate <NSObject>

enum {
    CMSetControllerChangeInsert = 1,
    CMSetControllerChangeDelete = 2,
    CMSetControllerChangeMove = 3,
    CMSetControllerChangeUpdate = 4
};
typedef NSUInteger CMSetControllerChangeType;

@optional
- (void)controllerWillChangeContent:(CMSetController *)controller;

@optional
- (void)controller:(CMSetController *)controller didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(CMSetControllerChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;

@optional
- (void)controller:(CMSetController *)controller didChangeSection:(id<CMSetControllerSectionInfo>)sectionInfo atIndex:(NSUInteger)index forChangeType:(CMSetControllerChangeType)type;

@optional
- (void)controllerDidChangeContent:(CMSetController *)controller;

@end

enum {
    CMSetControllerInconsistentStateError = 1,
    CMSetControllerFailedError = 2
};
