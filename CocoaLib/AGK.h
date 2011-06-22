//
//  AGK.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-11-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef NDEBUG
#define AGKTrace(format, ...)
#else
#define AGKTrace(format, ...) NSLog(@"[DEBUG] " format, ## __VA_ARGS__)
#endif

#define AGKMark() AGKTrace(@"%s", __PRETTY_FUNCTION__)

void AGKLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
void AGKLogRotate(void);
void AGKInitLog(int startsToLog);
NSArray *AGKLogs(void);

#define N(x) ([NSNumber numberWithLongLong:(long long)(x)])
#define F(x) ([NSNumber numberWithDouble:(double)(x)])
#define B(x) ([NSNumber numberWithBool:(bool)(x)])

#define NSDICT(...) [NSDictionary dictionaryWithObjectsAndKeys: __VA_ARGS__, nil]

#define NSARRAY(...) [NSArray arrayWithObjects: __VA_ARGS__, nil]