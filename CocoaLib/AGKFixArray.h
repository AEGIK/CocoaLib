//
//  AGKFixArray.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-08-07.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AGKFixArray : NSObject<NSCoding> 

- (void)setObject:(id)object atIndex:(NSUInteger)index;
- (id)objectAtIndex:(NSUInteger)index;
- (void)setUnsignedInteger:(NSUInteger)i atIndex:(NSUInteger)index;
- (NSUInteger)unsignedIntegerAtIndex:(NSUInteger)index;
+ (id)arrayWithSize:(NSUInteger)size;
- (id)initWithSize:(NSUInteger)size;
- (void)removeAllObjects;

@property (readonly, assign, nonatomic) NSUInteger count;

@end
