//
//  NSString+Extras.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-14-09.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>
static inline NSString *uintToString(unsigned long long i) {
	return [NSString stringWithFormat:@"%qu", i];
}

static inline NSString *intToString(signed long long i) {
	return [NSString stringWithFormat:@"%qi", i];
}

static inline NSString *doubleToString(double d) {
	return [NSString stringWithFormat:@"%f", d];
}

void bytesToHex(unsigned char *bytes, char *targetBuffer, NSUInteger length);
NSString *bytesToHexString(unsigned char *bytes, NSUInteger length);

@interface NSString(Extras)
- (BOOL)contains:(NSString *)string;
@end
