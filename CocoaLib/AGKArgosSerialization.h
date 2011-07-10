//
//  AGKArgosSerialization.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-11-07.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _AGKArgosProtocol
{
	AGKArgosProtocolInt00 = 0x00,
    AGKArgosProtocolInt7F = 0x7F,
	AGKArgosProtocolFalse = 0x80,
    AGKArgosProtocolTrue = 0x81,
    AGKArgosProtocolDoubleZero = 0x82,
	AGKArgosProtocolDouble = 0x83,
    AGKArgosProtocolDateMilliseconds = 0x84,
    AGKArgosProtocolDateSeconds = 0x85,
    AGKArgosProtocolDateHours = 0x86,
    AGKArgosProtocolMinusOne = 0x87,
    AGKArgosProtocol1ByteInteger = 0x88,
    AGKArgosProtocol8BytesInteger = 0x8F,
    AGKArgosProtocolStringLen00 = 0x90,
    AGKArgosProtocolStringLen0D = 0x9D,
    AGKArgosProtocolStringVar255 = 0x9E,
    AGKArgosProtocolStringVar65535 = 0x9F,
    AGKArgosProtocolArrayLen00 = 0xA0,
    AGKArgosProtocolArrayLen0D = 0xAD,
    AGKArgosProtocolArrayVar255 = 0xAE,
    AGKArgosProtocolArrayVar65535 = 0xAF,
    AGKArgosProtocolMapLen00 = 0xB0,
    AGKArgosProtocolMapLen0D = 0xBD,
    AGKArgosProtocolMapVar255 = 0xBE,
    AGKArgosProtocolMapVar65535 = 0xBF,
    AGKArgosProtocolSymbolId00 = 0xC0,
    AGKArgosProtocolSymbolId2D = 0xED,
    AGKArgosProtocolSymbol2Eto12D = 0xEE,
    AGKArgosProtocolNull = 0xEF,
    AGKArgosProtocolByteArrayLen00 = 0xF0,
    AGKArgosProtocolByteArrayLen0D = 0xFD,
    AGKArgosProtocolByteArrayVar255 = 0xFE,
    AGKArgosProtocolByteArrayVar65535 = 0xFF,
} AGKArgosProtocol;

@interface AGKArgosSerialize : NSObject {}

- (void)writeInteger:(int)byteWidth value:(int64_t)value;
- (void)begin;
- (void)add:(id)object;
- (NSData *)serialize;
- (NSData *)serialize:(NSObject *)object;

@end

@interface AGKArgosDeserialize : NSObject {}
- (id)deserialize:(NSData *)data;

@end