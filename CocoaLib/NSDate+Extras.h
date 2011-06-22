//
//  NSDate+Extras.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-17-08.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDate(Extras)
- (NSDate *)roundToDayUTC;
- (NSDate *)roundToDayLocal;
- (NSDate *)addDays:(NSInteger)daysToAdd;
+ (NSDate *)dateWithMillisecondsSinceEpoch:(int64_t)milliseconds;
@end
