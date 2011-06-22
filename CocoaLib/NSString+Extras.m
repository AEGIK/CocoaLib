//
//  NSString+Extras.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-14-09.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSString+Extras.h"

void bytesToHex(unsigned char *bytes, char *targetBuffer, NSUInteger length) {
	static char *hex = "0123456789abcdef";
	int k = 0;
	for (NSUInteger i = 0; i < length; i++) {
		unsigned char c = bytes[i];
		targetBuffer[k] = hex[c >> 4];
		targetBuffer[k + 1] = hex[c & 0x0f];
		k += 2;
	}	
}

NSString *bytesToHexString(unsigned char *c, NSUInteger length) {
	char *targetBuffer = malloc((length * 2 + 1) * sizeof(char) + 1);
	targetBuffer[length * 2] = 0;
	bytesToHex(c, targetBuffer, length);
	NSString *string = [NSString stringWithCString:targetBuffer encoding:NSASCIIStringEncoding];
	free(targetBuffer);
	return string;
}

@implementation NSString(Extras)
- (BOOL)contains:(NSString *)string {
	return [self rangeOfString:string].location != NSNotFound;
}
@end


