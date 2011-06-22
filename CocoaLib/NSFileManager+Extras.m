//
//  NSFileManager+Extras.m
//  Voddler
//
//  Created by Christoffer Lernö on 2011-28-03.
//  Copyright 2011 Aegik AB. All rights reserved.
//

#import "NSFileManager+Extras.h"

@implementation NSFileManager (Extras)

+ (NSString *)userDirectory:(NSSearchPathDirectory)directory 
{
    NSArray *array = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    return [array count] ? [array objectAtIndex:0] : nil;
}

+ (NSString *)directory:(NSString *)directory inUserDirectory:(NSSearchPathDirectory)userDirectory 
{
    return [[self userDirectory:userDirectory] stringByAppendingPathComponent:directory];
}

- (NSError *)setupDirectory:(NSString *)directory 
{
    NSError *error = nil;
    [self createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error];
    return error;
}

@end
