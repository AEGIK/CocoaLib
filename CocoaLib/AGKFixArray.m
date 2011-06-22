//
//  AGKFixArray.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-08-07.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "AGKFixArray.h"

static NSString *const ValuesKey = @"values";

@interface AGKFixArray() {
@private
    __strong id* _objects;
}
@end

@implementation AGKFixArray
@synthesize count = _count;

- (id)initWithCoder:(NSCoder *)coder
{
	if ((self = [super init])) {
		NSArray *array = [coder decodeObjectForKey:ValuesKey];
		_count = [array count];
		_objects = (__strong id *)calloc(_count, sizeof(id));
		for (NSUInteger i = 0; i < _count; i++)
		{
			id object = [array objectAtIndex:i];
			_objects[i] = object != [NSNull null] ? object : nil;
		}
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:_count];
	for (NSUInteger i = 0; i < _count; i++)
	{
		[array addObject:_objects[i] ? _objects[i] : [NSNull null]];
	}
	[coder encodeObject:array forKey:ValuesKey];
}

- (id)initWithSize:(NSUInteger)size
{
	if ((self = [super init])) {
        _count = size;
        _objects = (__strong id *)calloc(size, sizeof(id));        
    }
    return self;
}

+ (id)arrayWithSize:(NSUInteger)size
{
	return [[self alloc] initWithSize:size];
}

- (void)setObject:(id)object atIndex:(NSUInteger)index
{
	if (index > _count) [NSException raise:NSRangeException format:@"Index exceeded %d (was: %d)", _count, index];
	if (_objects[index] == object) return;
	_objects[index] = object;
}

- (void)removeAllObjects 
{
    for (NSUInteger i = 0; i < _count; i++) {
        _objects[i] = nil;
    }
}

- (id)objectAtIndex:(NSUInteger)index
{
	if (index > _count) [NSException raise:NSRangeException format:@"Index exceeded %d (was: %d)", _count, index];
	return _objects[index];
}

- (void)setUnsignedInteger:(NSUInteger)i atIndex:(NSUInteger)index
{
	[self setObject:[NSNumber numberWithUnsignedInteger:i] atIndex:index];
}

- (NSUInteger)unsignedIntegerAtIndex:(NSUInteger)index
{
	return [[self objectAtIndex:index] unsignedIntegerValue];
}


@end

