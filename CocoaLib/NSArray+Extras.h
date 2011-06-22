//
//  NSArray+Extras.h
//  FCJ
//
//  Created by Christoffer Lernö on 2010-28-04.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray(Extras)

// Create an array of floats
+ (NSArray *)arrayElements:(NSUInteger)count ofDoubles:(double)d1, ...;

// Create an array of ints
+ (NSArray *)arrayElements:(NSUInteger)count ofInts:(int)i1, ...;

// Select a random element from this array using random(). Returns nil if the array is empty.
- (id)randomObject;

// Return the first object, in the array, or nil if empty.
- (id)firstObject;

// Return an array formed by applying a block to all elements.
- (NSArray *)collect:(id(^)(id))collectBlock;

// Return an array formed by all elements that respond NO to the block.
- (NSArray *)reject:(BOOL(^)(id))rejectBlock;

// Return an array formed by all elements that respond YES to the block.
- (NSArray *)select:(BOOL(^)(id))selectBlock;

@end

@interface NSMutableArray(Extras)
- (void)removeFirst;
- (id)removeRandomObject;
- (id)removeFirstObject;

@end