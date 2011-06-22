//
//  NSData+Extras.m
//  AGKCocoaLib
//
//  Created by Christoffer Lernö on 2011-15-02.
//  Copyright 2011 Aegik AB. All rights reserved.
//

#import "NSData+Extras.h"


inline static unsigned char hexCharToNibble(char c) {
    if (c >= '0' && c <= '9') return (unsigned char)(c - '0');
    if (c >= 'A' && c <= 'F') return (unsigned char)(c - 'A' + 10);
    if (c >= 'a' && c <= 'f') return (unsigned char)(c - 'a' + 10);
    return 0xFF;
}

@implementation NSData(Extras)

+ (NSData *)dataWithHexString:(NSString *)hexString {
    NSUInteger length = [hexString length];
    if (length % 2 == 1) [NSException raise:NSGenericException format:@"Illegal hex data - illegal length %d", length];
    if (length == 0) return [NSData data];
    length >>= 1;
    unsigned char *theBytes = malloc(sizeof(unsigned char) * length);
    const char *sourceHex = [hexString cStringUsingEncoding:NSASCIIStringEncoding];
    if (!sourceHex) [NSException raise:NSGenericException format:@"Illegal hex data - conversion to ASCII failed"];
    for (NSUInteger i = 0; i < length; i++) {
        theBytes[i] = (unsigned char)(hexCharToNibble(*sourceHex++) << 4) | hexCharToNibble(*sourceHex++);
    }
    return [[NSData alloc] initWithBytesNoCopy:theBytes length:length];
}

@end
