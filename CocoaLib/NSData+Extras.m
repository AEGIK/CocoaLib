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

+ (NSData *)dataWithHexString:(NSString *)hexString 
{
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

+ (NSData *)dataWithDatas:(NSData *)data, ... 
{
    size_t totalSize = [data length];
    va_list list;
    va_start(list, data);
    void *aData;
    while ((aData = va_arg(list, void *)) != nil) {
        totalSize += [(__bridge NSData *)aData length];
    }
    va_end(list);
    void *result = malloc(totalSize);
    [data getBytes:result length:[data length]];
    va_start(list, data);
    void *current = result + [data length];
    while ((aData = va_arg(list, void *)) != nil) {
        [(__bridge NSData *)aData getBytes:current length:[(__bridge NSData *)aData length]];
        current += [(__bridge NSData *)aData length];
    }
    va_end(list);
    return [[NSData alloc] initWithBytesNoCopy:result length:totalSize freeWhenDone:YES];
}
- (NSData *)dataWithBigEndian16BitSizePrefix
{
    NSMutableData *newData = [[NSMutableData alloc] initWithCapacity:[self length] + 2];
    [newData writeBigEndianShort:(uint16_t)[self length]];
    [newData appendData:self];
    return newData;
}
@end

@implementation NSMutableData (Extras)

- (void)writeByte:(NSUInteger)byte
{
    NSAssert(byte < 0x100, @"Byte overflow");
    uint8_t array[1];
    array[0] = (uint8_t)byte;
    [self appendBytes:array length:1];
}

- (void)writeBigEndianShort:(uint16_t)aShort
{
    uint8_t array[2];
    array[0] = aShort >> 8;
    array[1] = aShort & 0xFF;
    [self appendBytes:array length:2];
}

- (void)writeBigEndianInteger:(uint32_t)anInteger
{
    uint8_t array[4];
    array[0] = anInteger >> 24;
    array[1] = (anInteger >> 16) & 0xFF;
    array[2] = (anInteger >> 8) & 0xFF;
    array[3] = anInteger & 0xFF;
    [self appendBytes:array length:4];    
}

- (void)writeBigEndianLong:(uint64_t)aLong
{
    uint8_t array[8];
    array[0] = aLong >> 56;
    array[1] = (aLong >> 48) & 0xFF;
    array[2] = (aLong >> 40) & 0xFF;
    array[3] = (aLong >> 32) & 0xFF;
    array[4] = (aLong >> 24) & 0xFF;
    array[5] = (aLong >> 16) & 0xFF;
    array[6] = (aLong >> 8) & 0xFF;
    array[7] = aLong & 0xFF;
    [self appendBytes:array length:8];        
}

- (void)writeVar255Bytes:(NSData *)data
{
    [self writeByte:[data length]];
    [self appendData:data];    
}

- (void)writeVar65535Bytes:(NSData *)data
{
    [self writeBigEndianShort:(uint16_t)[data length]];
    [self appendData:data];    
}
- (void)write255UTFString:(NSString *)string
{
    [self writeVar255Bytes:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)write65535UTFString:(NSString *)string
{
    [self writeVar65535Bytes:[string dataUsingEncoding:NSUTF8StringEncoding]];
    
}

@end

