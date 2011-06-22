//
//  NSDictionary+Extras.h
//  FCJ
//
//  Created by Christoffer Lernö on 2010-03-05.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary(Extras)
- (void)setUnsignedInteger:(NSUInteger)uinteger forKey:(id)key;
- (void)setInteger:(NSInteger)integer forKey:(id)key;
- (void)setDouble:(double)d forKey:(id)key;
- (void)retainObjectsForKeys:(NSArray *)keys;
@end

@interface NSDictionary(Extras) 

- (BOOL)boolForKey:(id)key;
- (int)intForKey:(id)key;
- (NSInteger)integerForKey:(id)key;
- (NSUInteger)unsignedIntegerForKey:(id)key;
- (BOOL)hasObjectForKey:(id)key;
- (double)doubleForKey:(id)key;
- (long long)longLongForKey:(id)key;
- (NSString *)compactDescription;
- (NSArray *)arrayForKeyPath:(NSString *)keyPath;

@end
