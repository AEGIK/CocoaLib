//
//  NSBundle+Extras.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-27-09.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSBundle+Extras.h"

@implementation NSBundle(Extras)

+ (NSString *)version 
{
    NSString *appVersion = (__bridge NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle() , (__bridge CFStringRef)@"CFBundleShortVersionString");
	return appVersion ? appVersion : @"1.0";
}

+ (NSString *)build 
{
	NSString *build = (__bridge NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), (__bridge CFStringRef)@"CFBundleVersion");
	return build ? build : @"1";
}

@end
