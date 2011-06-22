//
//  NSArray+Extras.m
//  FCJ
//
//  Created by Christoffer Lernö on 2010-28-04.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSArray+Extras.h"


@implementation NSArray(Extras)

+ (NSArray *)arrayElements:(NSUInteger)count ofInts:(int)i1, ...
{
	if (!count) return [NSArray array];
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:count];
	va_list list;
	[array addObject:[NSNumber numberWithInt:i1]];
	va_start(list, i1); 
	for (NSUInteger i = 1; i < count; i++)
	{
		int ival = va_arg(list, int);
		[array addObject:[NSNumber numberWithInt:ival]];
	}
	va_end(list);
    return [[NSArray alloc] initWithArray:array];
}

+ (NSArray *)arrayElements:(NSUInteger)count ofDoubles:(double)d1, ...
{
	if (!count) return [NSArray array];
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:count];
	va_list list;
	[array addObject:[NSNumber numberWithDouble:d1]];
	va_start(list, d1); 
	for (NSUInteger i = 1; i < count; i++)
	{
		double d = va_arg(list, double);
		[array addObject:[NSNumber numberWithDouble:d]];
	}
	va_end(list);
    return [[NSArray alloc] initWithArray:array];
}

-(id)firstObject
{
	return [self count] ? [self objectAtIndex:0] : nil;
}

-(id)randomObject
{
	NSUInteger objects = [self count];
	if (objects) {
		return [self objectAtIndex:((unsigned long)random() % objects)];
	}
	return nil;
}

- (NSArray *)collect:(id(^)(id))collectBlock {
	NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:[self count]];
	for (id element in self) {
		id result = collectBlock(element);
		[newArray addObject:result ? result : [NSNull null]];
	}
    return [[NSArray alloc] initWithArray:newArray];
}

- (NSArray *)reject:(BOOL(^)(id))rejectBlock 
{
	NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:[self count]];
	for (id element in self) {
        if (!rejectBlock(element)) [newArray addObject:element];
	}
    return [[NSArray alloc] initWithArray:newArray];
}

- (NSArray *)select:(BOOL(^)(id))selectBlock 
{
	NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:[self count]];
	for (id element in self) {
        if (selectBlock(element)) [newArray addObject:element];
	}
    return [[NSArray alloc] initWithArray:newArray];
}

@end

@implementation NSMutableArray(Extras)

- (void)removeFirst
{
	if ([self count] > 0) {
		[self removeObjectAtIndex:0];
	}
}

- (id)removeFirstObject 
{
	if (![self count]) return nil;
	id object = [self objectAtIndex:0];
	[self removeObjectAtIndex:0];
	return object;
}

- (id)removeRandomObject
{
	NSUInteger index = (unsigned long)random() % [self count];
	id object = [self objectAtIndex:index];
	[self removeObjectAtIndex:index];
	return object;
}

@end
