//
//  NSBundle+Extras.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-27-09.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSBundle+Extras.h"

@implementation NSBundle(Extras)

+ (NSString *)version {
	CFStringRef appVersion = (CFStringRef)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle() , (CFStringRef)@"CFBundleShortVersionString");
	return appVersion ? objc_unretainedObject(appVersion) : @"1.0";
}

+ (NSString *)build {
	CFStringRef build = (CFStringRef)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), (CFStringRef)@"CFBundleVersion");
	return build ? objc_unretainedObject(build) : @"1";
}

@end
