//
//  NSDate+Extras.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-17-08.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSDate+Extras.h"


@implementation NSDate(Extras)

- (NSDate *)roundToDayTimezone:(NSTimeZone *)timezone
{
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:timezone];
	return [calendar dateFromComponents:[calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:self]];    
}

- (NSDate *)roundToDayUTC 
{
	static __strong NSTimeZone *timeZone = nil;
	if (!timeZone) timeZone = [[NSTimeZone alloc] initWithName:@"UTC"];
    return [self roundToDayTimezone:timeZone];
}

- (NSDate *)roundToDayLocal 
{
    return [self roundToDayTimezone:[NSTimeZone localTimeZone]];
}

- (NSDate *)addDays:(NSInteger)daysToAdd 
{
	return [NSDate dateWithTimeInterval:daysToAdd * 3600 * 24 sinceDate:self];
}

+ (NSDate *)dateWithMillisecondsSinceEpoch:(int64_t)milliseconds 
{
    return [NSDate dateWithTimeIntervalSince1970:milliseconds / 1000.0];
}

@end
