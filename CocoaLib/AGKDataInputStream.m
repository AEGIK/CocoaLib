//
//  AGKDataInputStream.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-03-07.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import "AGKDataInputStream.h"
#import "NSDate+Extras.h"

@interface AGKDataInputStream() {}
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) uint8_t *end;
@property (nonatomic, assign) uint8_t *current;
@end

@implementation AGKDataInputStream

@synthesize data = _data, end = _end, current = _current;

- (id)initWithData:(NSData *)data
{
    if ((self = [super init])) {
        _data = data;
        _current = (uint8_t *)[data bytes];
        _end = _current + [data length];
    }
    return self;
}

- (void)reset
{
    [self setCurrent:(uint8_t *)[[self data] bytes]];
}

- (BOOL)mayRead:(NSInteger)bytesToRead
{
    return [self current] + bytesToRead <= [self end];
}

- (NSInteger)readUnsignedShort
{
    if (![self mayRead:2]) return -1;
    uint8_t hiByte = *(_current++);
    uint8_t loByte = *(_current++);
    return hiByte << 8 | loByte;
}

- (BOOL)hasData
{
    return [self mayRead:1];
}

- (NSInteger)readByte
{
    if (![self mayRead:1]) return -1;
    return *(_current++);
}

- (NSData *)readVariable255Bytes
{
    NSInteger length = [self readByte];
    if (length < 0) return nil;
    if (length == 0) return [NSData data];
    if (![self mayRead:length]) return nil;
    return [self readDataLength:(NSUInteger)length];
}

- (NSData *)readDataLength:(NSUInteger)length
{
    NSData *data = [[NSData alloc] initWithBytes:_current length:(NSUInteger)length];
    _current += length;    
    return data;
}

- (NSString *)readStringLength:(NSUInteger)length
{
    NSData *data = [self readDataLength:length];
    if (!data) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData *)readVariable65535Bytes
{
    NSInteger length = [self readUnsignedShort];
    if (length < 0) return nil;
    if (length == 0) return [NSData data];
    if (![self mayRead:length]) return nil;
    NSData *data = [[NSData alloc] initWithBytes:_current length:(NSUInteger)length];
    _current += length;
    return data;
}

- (int64_t)readLongUnsafe
{
    uint64_t l = 0;
    for (int i = 0; i < 8; i++) {
        uint8_t ui = *(_current++);
        l = (l << 8) | ui;
    }
    return (int64_t)l;
}

- (NSDate *)readMillisecondsSinceEpoch
{
    if (![self mayRead:8]) return nil;
    int64_t milliseconds = [self readLongUnsafe];
    return [NSDate dateWithMillisecondsSinceEpoch:milliseconds];
}

- (NSString *)readTinyString
{
    NSData *data = [self readVariable255Bytes];
    if (!data) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
@end
