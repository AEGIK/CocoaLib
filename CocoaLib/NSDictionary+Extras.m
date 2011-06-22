//
//  NSDictionary+Extras.m
//  FCJ
//
//  Created by Christoffer Lernö on 2010-03-05.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSDictionary+Extras.h"

@implementation NSDictionary(Extras)


- (BOOL)boolForKey:(id)key {
	id object = [self objectForKey:key];
	SEL selector = @selector(boolValue);
	if (!object || ![object respondsToSelector:selector]) return NO;
	return [object performSelector:selector] ? YES : NO;
}

- (NSUInteger)unsignedIntegerForKey:(id)key {
	id object = [self objectForKey:key];
    if ([object respondsToSelector:@selector(unsignedIntegerValue)]) return [object unsignedIntegerValue];
	return (NSUInteger)[self integerForKey:key];
}

- (NSInteger)integerForKey:(id)key 
{
	id object = [self objectForKey:key];
    if ([object respondsToSelector:@selector(integerValue)]) return [object integerValue];
    return 0;
}

- (int)intForKey:(id)key 
{
	id object = [self objectForKey:key];
    if ([object respondsToSelector:@selector(intValue)]) return [object intValue];
    return 0;
}

- (long long)longLongForKey:(id)key 
{
	id object = [self objectForKey:key];
    if ([object respondsToSelector:@selector(longLongValue)]) return [object longLongValue];
    return [self intForKey:key];
}

- (double)doubleForKey:(id)key 
{
	id object = [self objectForKey:key];
    if ([object respondsToSelector:@selector(doubleValue)]) return [object doubleValue];
    return 0;
}

- (BOOL)hasObjectForKey:(id)key 
{
	id object = [self objectForKey:key];
	return object && object != [NSNull null];
}

- (NSString *)compactDescription 
{
	NSMutableString *string = [NSMutableString stringWithCapacity:50];
	for (id key in [self keyEnumerator]) {
		[string appendFormat:([string length] ? @", %@: %@" : @"%@: %@"), key, [self valueForKey:key]];
	}
	return [NSString stringWithFormat:@"{ %@ }", string];
}

- (NSArray *)arrayForKeyPath:(NSString *)keyPath 
{
	id value = [self valueForKeyPath:keyPath];
	if (!value) return nil;
	if ([value isKindOfClass:[NSArray class]]) return value;
	return [NSArray arrayWithObject:value];
}
@end

@implementation NSMutableDictionary(Extras)

- (void)setUnsignedInteger:(NSUInteger)uinteger forKey:(id)key
{
	[self setObject:[NSNumber numberWithUnsignedInteger:uinteger] forKey:key];
}

- (void)setDouble:(double)d forKey:(id)key
{
	[self setObject:[NSNumber numberWithDouble:d] forKey:key];
}

- (void)setInteger:(NSInteger)integer forKey:(id)key
{
	[self setObject:[NSNumber numberWithInteger:integer] forKey:key];
}

- (void)retainObjectsForKeys:(NSArray *)keys
{
	for (id key in [self allKeys]) {
		if (![keys containsObject:key]) {
			[self removeObjectForKey:key];
		}
	}
}

@end

