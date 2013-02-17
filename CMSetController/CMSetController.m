//
//  CMSetController.m
//
//  Created by Samuel Ford on 4/6/12.
//  Copyright (c) Samuel Ford. All rights reserved.
//
//  https://github.com/causticmango/CMSetController
//

#import "CMSetController.h"

static NSString * const kCMSetControllerErrorDomain = @"com.causticmango.CMSetController";
static void * const kCMSetContext = (void *)@"com.causticmango.CMSetController.set";
static void * const kCMItemContext = (void *)@"com.causticmango.CMSetController.item";

#pragma mark - Hidden Class - _CMSectionHolder

@interface _CMSectionHolder : NSObject <CMSetControllerSectionInfo> {
@public
    NSRange _range;
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *allObjects;

- (id)initWithName:(NSString *)name allObjects:(NSArray *)allObjects range:(NSRange)range;

@end

@implementation _CMSectionHolder

@synthesize name = _name;
@synthesize allObjects = _allObjects;

- (id)init
{
    return [self initWithName:@"" allObjects:[NSArray array] range:NSMakeRange(0, 0)];
}

- (id)initWithName:(NSString *)name allObjects:(NSArray *)allObjects range:(NSRange)range
{
    if ((self = [super init])) {
        _name = name;
        _allObjects = allObjects;
        _range = range;
    }
    
    return self;
}

- (NSUInteger)numberOfObjects
{
    return _range.length;
}

- (NSArray *)objects
{
    return [_allObjects subarrayWithRange:_range];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"section \"%@\" %@", _name, NSStringFromRange(_range)];
}

@end

#pragma mark - Private Interface

@interface CMSetController ()

- (void)checkSanity;
- (void)setUpObservation;
- (void)tearDownObservation;
- (void)startObservingObject:(id)item;
- (void)stopObservingObject:(id)item;
- (void)reloadQueryData;
- (NSString *)sectionNameForObject:(id)item;
- (NSUInteger)insertionPointForObject:(id)item;
- (_CMSectionHolder *)sectionContainingLocation:(NSUInteger)location;

@end

#pragma mark - Back to Our Regularly Scheduled Implementation ...

@implementation CMSetController {
    NSString *_sectionNameKeyPath;
    NSArray *_sortDescriptors;
    BOOL _needsRefresh;
    BOOL _observing;
    NSMutableArray *_sections;
    NSMutableArray *_sortedItems;
}

@synthesize observed = _observed;
@synthesize setKeyPath = _setKeyPath;
@synthesize observedKeyPaths = _observedKeyPaths;
@synthesize delegate = _delegate;

- (id)init
{
    return [self initWithObserved:nil setKeyPath:nil keyPaths:nil sectionNameKeyPath:nil sortDescriptors:nil delegate:nil];
}

- (id)initWithObserved:(id)observed 
            setKeyPath:(NSString *)setKeyPath
              keyPaths:(NSArray *)keyPaths
    sectionNameKeyPath:(NSString *)sectionNameKeyPath 
       sortDescriptors:(NSArray *)descriptors 
              delegate:(id<CMSetControllerDelegate>)delegate
{
    if ((self = [super init])) {
        _observed = observed;
        _setKeyPath = setKeyPath;
        _observedKeyPaths = keyPaths;
        _sectionNameKeyPath = sectionNameKeyPath;
        _sortDescriptors = [descriptors copy];
        _delegate = delegate;
        
        _needsRefresh = YES;
        _observing = NO;
        
        _sections = [[NSMutableArray alloc] init];
        _sortedItems = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    if (_observing) [self tearDownObservation];
}

#pragma mark - Property Implementations

- (NSString *)sectionNameKeyPath
{
    return _sectionNameKeyPath;
}

- (void)setSectionNameKeyPath:(NSString *)sectionNameKeyPath
{
    _sectionNameKeyPath = sectionNameKeyPath;
    _needsRefresh = YES;
}

- (NSArray *)observedKeyPaths
{
    return [_observedKeyPaths copy];
}

- (void)setObservedKeyPaths:(NSArray *)observedKeyPaths
{
    [self tearDownObservation];
    
    _observedKeyPaths = [observedKeyPaths copy];
    _needsRefresh = YES;
    
    [self setUpObservation];
}

- (NSArray *)sortDescriptors
{
    return [_sortDescriptors copy];
}

- (void)setSortDescriptors:(NSArray *)sortDescriptors
{
    _sortDescriptors = [sortDescriptors copy];
    _needsRefresh = YES;
}

- (NSArray *)sections
{
    if (_needsRefresh) [self reloadQueryData];
    
    return [_sections copy];
}

#pragma mark - Public Methods

- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSIndexPath *)indexPathForObject:(id)object
{
    return nil;
}

- (BOOL)performQuery:(NSError *__autoreleasing *)error
{
    BOOL success = NO;
    
    @try {
        [self checkSanity];
        [self setUpObservation];
        [self reloadQueryData];
        success = YES;
    }
    @catch (NSException *exception) {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:exception.name, exception.reason, nil]
                                                             forKeys:[NSArray arrayWithObjects:NSLocalizedDescriptionKey, NSLocalizedFailureReasonErrorKey, nil]];
        
        *error = [NSError errorWithDomain:kCMSetControllerErrorDomain 
                                     code:[exception.reason isEqualToString:NSInternalInconsistencyException] ? CMSetControllerInconsistentStateError : CMSetControllerFailedError
                                 userInfo:userInfo];
    }
    @finally {
        return success;
    }
}

- (void)stopObserving
{
    if (_observing) [self tearDownObservation];
}

#pragma mark - Internal Methods

- (void)checkSanity
{
    if (!_observed) {
        [NSException raise:NSInternalInconsistencyException format:@"observed object cannot be nil"];
    }
    
    if (!_setKeyPath) {
        [NSException raise:NSInternalInconsistencyException format:@"set key path cannot be nil"];
    }
    
    id set = [_observed valueForKeyPath:_setKeyPath];
    if (![set isKindOfClass:[NSSet class]]) {
        [NSException raise:NSInternalInconsistencyException format:@"set key path does not return a set"];
    }
    
    if (_sortDescriptors.count == 0) {
        [NSException raise:NSInternalInconsistencyException format:@"no sort descriptors supplied"];
    }
    
    if (_observedKeyPaths.count == 0) {
        [NSException raise:NSInternalInconsistencyException format:@"no observed key paths"];
    }
}

- (void)setUpObservation
{
    [self checkSanity];
    
    if (_observing) return;
    
    [_observed addObserver:self 
                forKeyPath:_setKeyPath 
                   options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueChangeInsertion | NSKeyValueChangeRemoval 
                   context:kCMSetContext];

    for (id item in [_observed valueForKeyPath:_setKeyPath]) [self startObservingObject:item];
    
    _observing = YES;
}

- (void)tearDownObservation
{
    if (!_observing) return;
    
    [_observed removeObserver:self forKeyPath:_setKeyPath];
    
    for (id item in [_observed valueForKeyPath:_setKeyPath]) [self stopObservingObject:item];
    
    _observing = NO;
}

- (void)startObservingObject:(id)item
{
    for (NSString *key in _observedKeyPaths) {
        [item addObserver:self forKeyPath:key 
                  options:NSKeyValueChangeSetting
                  context:kCMItemContext];
    }    
}

- (void)stopObservingObject:(id)item
{
    for (NSString *key in _observedKeyPaths) {
        [item removeObserver:self forKeyPath:key];
    }
}

- (NSString *)sectionNameForObject:(id)item
{
    if (_sectionNameKeyPath && ![_sectionNameKeyPath isEqualToString:@""])
        return [[item valueForKeyPath:_sectionNameKeyPath] description];
    else
        return @"";
    
}

- (NSUInteger)insertionPointForObject:(id)item
{
    NSUInteger top = _sortedItems.count;
    NSUInteger index = 0;
    
    while (index < top) {
        NSInteger midpoint = (index + top) / 2;
        id comparedItem = [_sortedItems objectAtIndex:midpoint];
        
        NSComparisonResult compareResult = NSOrderedSame;
        
        for (NSSortDescriptor *sortDescriptor in _sortDescriptors) {
            compareResult = [sortDescriptor compareObject:item toObject:comparedItem];
            if (compareResult != NSOrderedSame) break;
        }
        
        if (compareResult == NSOrderedSame) break;
        
        if (compareResult == NSOrderedDescending) index = midpoint + 1;
        if (compareResult == NSOrderedAscending) top = midpoint;
    }

    return index;
}

- (_CMSectionHolder *)sectionContainingLocation:(NSUInteger)location
{
    for (_CMSectionHolder *section in _sections) {
        if (NSLocationInRange(location, section->_range)) return section;
    }
    
    return nil;
}

- (NSUInteger)indexOfSectionContainingLocation:(NSUInteger)location
{
    _CMSectionHolder *section = [self sectionContainingLocation:location];
    return section == nil ? _sections.count : [_sections indexOfObject:section];
}

- (_CMSectionHolder *)sectionForObject:(id)item
{
    return [self sectionContainingLocation:[_sortedItems indexOfObject:item]];
}

- (_CMSectionHolder *)sectionForSectionName:(NSString *)name
{
    _CMSectionHolder *section = nil;

    NSArray *matched = [_sections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", name]];
    if ([matched count] > 0) section = [matched objectAtIndex:0];
    
    return section;
}

- (void)reloadQueryData
{
    // clear out sections
    [_sections removeAllObjects];
    [_sortedItems removeAllObjects];
    
    // initial sort needs to be the section key
    
    NSSet *items = [_observed valueForKey:_setKeyPath];
        
    [_sortedItems addObjectsFromArray:[items allObjects]];
    [_sortedItems sortUsingDescriptors:_sortDescriptors];
    
    // now we've got them sorted, let's divide up into sections
    // yes, it's sloppy, but it's only half implemented
    
    NSRange currentSectionRange = NSMakeRange(0, _sortedItems.count);
    NSString *lastSectionName = nil;
    
    if (_sectionNameKeyPath && ![_sectionNameKeyPath isEqualToString:@""]) {
        for (NSUInteger currentIndex = 0; currentIndex < _sortedItems.count; currentIndex++) {
            id item = [_sortedItems objectAtIndex:currentIndex];
            NSString *currentSectionName = [self sectionNameForObject:item];
            
            if (currentSectionName != lastSectionName && ![currentSectionName isEqualToString:lastSectionName]) {
                // a new section starts here
                currentSectionRange.length = currentIndex - currentSectionRange.location;
                
                if (currentSectionRange.length > 0) {
                    _CMSectionHolder *section = [[_CMSectionHolder alloc] initWithName:lastSectionName allObjects:_sortedItems range:currentSectionRange];
                    [_sections addObject:section];                    
                }
                
                lastSectionName = currentSectionName;
                currentSectionRange.location = currentIndex;
                currentSectionRange.length = _sortedItems.count - currentIndex;
            }
        }
    }
    
    // sweep up the trailing section
    [_sections addObject:[[_CMSectionHolder alloc] initWithName:lastSectionName allObjects:_sortedItems range:currentSectionRange]];
    
    // ok, we're done

    _needsRefresh = NO;
}

#pragma mark - KVO Implementation

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // boy, this method needs refactoring something awful ...
    
    if ([_delegate respondsToSelector:@selector(controllerWillChangeContent:)]) [_delegate controllerWillChangeContent:self];
    
    if (context == kCMSetContext) {
        
        NSNumber *kind = [change objectForKey:NSKeyValueChangeKindKey];
        NSSet *new = [change objectForKey:NSKeyValueChangeNewKey];
        NSSet *old = [change objectForKey:NSKeyValueChangeOldKey];

        switch ([kind intValue]) {
            case NSKeyValueChangeInsertion:
                for (id item in new) {
                    // observe it
                    [self startObservingObject:item];
                    
                    // figure out where to put it
                    NSUInteger indexOfItem = [self insertionPointForObject:item];
                    [_sortedItems insertObject:item atIndex:indexOfItem];

                    // find the section by name
                    NSString *sectionNameForItem = [self sectionNameForObject:item];
                    __block _CMSectionHolder *section = nil;
                    __block NSUInteger indexOfSection = _sections.count - 1;
                    
                    [_sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        if ([sectionNameForItem isEqualToString:[obj name]]) {
                            section = obj;
                            indexOfSection = idx;
                            *stop = YES;
                        }
                    }];
                    
                    if (section == nil) {
                        // make a new section
                        section = [[_CMSectionHolder alloc] initWithName:sectionNameForItem allObjects:_sortedItems range:NSMakeRange(indexOfItem, 1)];

                        // figure out where to insert it
                        [_sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                            _CMSectionHolder *currentSection = obj;
                            if (currentSection->_range.location > indexOfItem) {
                                *stop = YES;
                            }
                            
                            indexOfSection = idx;
                            if (indexOfItem > (currentSection->_range.location + currentSection->_range.length - 1)) indexOfSection = idx + 1;
                        }];
                        
                        [_sections insertObject:section atIndex:indexOfSection];
                        
                    } else {
                        section->_range.length++;
                        if (section->_range.location > indexOfItem) section->_range.location = indexOfItem;
                    }

                    // push all the sections behind this one down
                    NSUInteger indexOfSectionToPush = indexOfSection + 1;
                    while (indexOfSectionToPush < _sections.count) {
                        section = [_sections objectAtIndex:indexOfSectionToPush];
                        section->_range.location++;
                        indexOfSectionToPush++;
                    }
                    
                    // notify
                    if ([_delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                        NSInteger row = indexOfItem - section->_range.location;
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:indexOfSection];
                        
                        [_delegate controller:self didChangeObject:item atIndexPath:nil forChangeType:CMSetControllerChangeInsert newIndexPath:indexPath];
                    }
                }
                break;
                
            case NSKeyValueChangeRemoval:
                for (id item in old) {
                    // stop observing it
                    [self stopObservingObject:item];
                    
                    // find it and remove it
                    NSUInteger indexOfItem = [_sortedItems indexOfObject:item];
                    
                    _CMSectionHolder *section = [self sectionContainingLocation:indexOfItem];
                    NSUInteger indexOfSection = [_sections indexOfObject:section];
                    
                    [_sortedItems removeObjectAtIndex:indexOfItem];
                    
                    // shrink up the section
                    section->_range.length--;

                    // move the sections below it up
                    NSUInteger indexOfSectionToPullUp = indexOfSection + 1;
                    while (indexOfSectionToPullUp < _sections.count) {
                        _CMSectionHolder *sectionToPullUp = [_sections objectAtIndex:indexOfSectionToPullUp];
                        sectionToPullUp->_range.location--;
                        indexOfSectionToPullUp++;
                    }
                    
                    // if the section is empty, yank it
                    if (section->_range.length == 0) {
                        [_sections removeObjectAtIndex:indexOfSection];
                        
                        // tell the delegate we yanked a section
                        if ([_delegate respondsToSelector:@selector(controllerDidChangeSection:atIndex:forChangeType:)]) {
                            [_delegate controller:self 
                                 didChangeSection:section 
                                          atIndex:indexOfSection 
                                    forChangeType:CMSetControllerChangeDelete];
                        }
                    }
                    
                    // notify
                    if ([_delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
                        NSInteger row = indexOfItem - section->_range.location;
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:indexOfSection];
                        
                        [_delegate controller:self didChangeObject:item atIndexPath:indexPath forChangeType:CMSetControllerChangeDelete newIndexPath:nil];
                    }
                }
                break;                
        }
        
    } else if (context == kCMItemContext) {
        
        // figure out which section it's in and what its index is
        NSUInteger originalIndexOfItem = [_sortedItems indexOfObject:object];
        _CMSectionHolder *originalSection = [self sectionContainingLocation:originalIndexOfItem];
        NSUInteger originalIndexOfSection = [_sections indexOfObject:originalSection];
        
        // yank it out & adjust the sections
        [_sortedItems removeObjectAtIndex:originalIndexOfItem];
        originalSection->_range.length--;
        
        NSUInteger sectionIndex = [_sections indexOfObject:originalSection];
        for (NSUInteger currentIndex = sectionIndex + 1; currentIndex < _sections.count; currentIndex++) {
            _CMSectionHolder *section = [_sections objectAtIndex:currentIndex];
            section->_range.location--;
        }
        
        // new figure out where it goes
        NSUInteger indexOfItem = [self insertionPointForObject:object];
        
        // put it in
        [_sortedItems insertObject:object atIndex:indexOfItem];
        
        // see if there's a section it should be in
        NSString *sectionName = [self sectionNameForObject:object];
        _CMSectionHolder *section = [self sectionForSectionName:sectionName];
        
        NSInteger sectionAdjustment = 0;
        BOOL didInsertSection = NO;
        
        // if there is no target section, then let's make one and add it
        if (section == nil || ![section.name isEqualToString:sectionName]) {
            // figure out which section our position says we're in
            sectionIndex = [self indexOfSectionContainingLocation:indexOfItem];
            
            section = [[_CMSectionHolder alloc] initWithName:sectionName allObjects:_sortedItems range:NSMakeRange(indexOfItem, 0)];
            [_sections insertObject:section atIndex:sectionIndex];
            
            didInsertSection = YES;
        }
        
        // grow the target section to accommodate it and push down the ones behind it
        section->_range.length++;
        sectionIndex = [_sections indexOfObject:section];
        
        for (NSUInteger currentIndex = sectionIndex + 1; currentIndex < _sections.count; currentIndex++) {
            _CMSectionHolder *currentSection = [_sections objectAtIndex:currentIndex];
            currentSection->_range.location++;
        }
        
        // figure out if we need to account for an adjustment
        if (didInsertSection && sectionIndex >= originalIndexOfSection && originalSection->_range.length == 0) sectionAdjustment = -1;
        if (!didInsertSection && originalIndexOfSection < sectionIndex && originalSection->_range.length == 0) sectionAdjustment = -1;

        // tell the delegate if we inserted a section
        if (didInsertSection && [_delegate respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)]) {
            [_delegate controller:self
                 didChangeSection:section
                          atIndex:sectionIndex + sectionAdjustment
                    forChangeType:CMSetControllerChangeInsert];
        }

        // if the original section is empty, remove it
        if (originalSection->_range.length == 0) {
            [_sections removeObject:originalSection];
            
            if ([_delegate respondsToSelector:@selector(controller:didChangeSection:atIndex:forChangeType:)]) {
                [_delegate controller:self
                     didChangeSection:originalSection
                              atIndex:originalIndexOfSection
                        forChangeType:CMSetControllerChangeDelete];
            }
        }
        
        // fire the move event for the row

        if ([_delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:originalIndexOfItem - originalSection->_range.location
                                                        inSection:originalIndexOfSection];
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexOfItem - section->_range.location
                                                           inSection:sectionIndex + sectionAdjustment];
            
            [_delegate controller:self 
                  didChangeObject:object 
                      atIndexPath:indexPath 
                    forChangeType:CMSetControllerChangeMove 
                     newIndexPath:newIndexPath];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    if ([_delegate respondsToSelector:@selector(controllerDidChangeContent:)]) [_delegate controllerDidChangeContent:self];
    
}

@end
