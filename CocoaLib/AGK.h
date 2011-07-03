//
//  AGK.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-11-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef DEBUG
#define AGKTrace(format, ...) NSLog(@"[DEBUG] " format, ## __VA_ARGS__)
#else
#define AGKTrace(format, ...)
#endif

#define TODO() NSAssert(NO, @"%s not implemented", __PRETTY_FUNCTION__)

#define AGKMark() AGKTrace(@"%s", __PRETTY_FUNCTION__)

void AGKLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
void AGKLogRotate(void);
void AGKInitLog(int startsToLog);
NSArray *AGKLogs(void);

#define N(x) ([NSNumber numberWithLongLong:(long long)(x)])
#define F(x) ([NSNumber numberWithDouble:(double)(x)])
#define B(x) ([NSNumber numberWithBool:(bool)(x)])

#define NSDICT(...) [[NSDictionary alloc] initWithObjectsAndKeys: __VA_ARGS__, nil]

#define NSARRAY(...) [NSArray arrayWithObjects: __VA_ARGS__, nil]

#define NSFORMAT(...) [NSString stringWithFormat: __VA_ARGS__, nil]

#define STRB(x) (x ? @"YES" : @"NO")
#define STRF(x) ([F(x) stringValue])
#define STRN(x) ([N(x) stringValue])