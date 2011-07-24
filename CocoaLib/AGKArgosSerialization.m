//
//  AGKArgosSerialization.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-11-07.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import "AGKArgosSerialization.h"
#import "AGKDataInputStream.h"
#import "AGK.h"

enum Constants
{
    MaxSymbolLength = 128,
};

@interface AGKArgosSerializer() {}
@property (nonatomic, strong) NSMutableDictionary *symbolList;
@property (nonatomic, assign) NSUInteger maxSymbols;
@property (nonatomic, strong) NSMutableData *currentData;
@end

@interface AGKArgosDeserializer() {}
- (id)deserialize;
@property (nonatomic, strong) NSMutableDictionary *symbolList;
@end

@implementation AGKArgosSerializer

@synthesize symbolList = _symbolList, maxSymbols = _maxSymbols, currentData = _currentData;

- (id)init 
{
	if ((self = [super init])) {
		_maxSymbols = AGKArgosProtocolSymbolId2D - AGKArgosProtocolSymbolId00 + 1 + 256;
		_symbolList = [[NSMutableDictionary alloc] initWithCapacity:_maxSymbols];
	}
	return self;
}

- (void)addByte:(uint8_t)toAdd 
{
	uint8_t b[1];
	b[0] = toAdd;
	[[self currentData] appendBytes:b length:1];	
}

- (void)writeInteger:(int)byteWidth value:(int64_t)value 
{
	for (int i = byteWidth - 1; i >= 0; i--) {
		[self addByte:(0xFF & (value >> (i * 8)))];
	}		
}

- (void)addInteger:(int64_t)value
{
    if (value == -1) {
		[self addByte:AGKArgosProtocolMinusOne];
		return;
	}
    
	static int maxZeroByte = AGKArgosProtocolInt7F - AGKArgosProtocolInt00;
	if (value >= 0 && value <= maxZeroByte) {
		[self addByte:(uint8_t)(AGKArgosProtocolInt00 + value)];
		return;
	}
    
	if (value > maxZeroByte && value < 256) {
		[self addByte:AGKArgosProtocol1ByteInteger];
		[self addByte:(uint8_t)(value - 128)];
		return;
	}
    
	uint8_t length = 8;
	for (uint8_t i = 1; i <= 7; i++)
	{
		long long max = (1LL << (8 * i - 1)) - 1;
		long long min = -max - 1;
		if (value >= min && value <= max) {
			length = i;
			break;
		}
	}
    
	[self addByte:AGKArgosProtocol1ByteInteger + length - 1];
	[self writeInteger:length value:value];
}


- (void)addDouble:(double)value
{
	if (value == 0.0) {
		[self addByte:AGKArgosProtocolDoubleZero];
	} else {
		[self addByte:AGKArgosProtocolDouble];
		long long *longValue = (long long *)&value;
		for (int i = 7; i >= 0; i--) {
			[self addByte:(0xFF & (*longValue >> (i * 8)))];
		}	
	}
}

- (void)writeSize:(NSUInteger)size zeroSize:(uint8_t)zeroSizeId maxSize:(uint8_t)lastFixSizeId
{
	uint8_t max = lastFixSizeId - zeroSizeId;
	if (size <= max) {
		[self addByte:(uint8_t)(zeroSizeId + size)];
        return;
	}
	if (size < 256) {
		[self addByte:lastFixSizeId + 1];
		[self writeInteger:1 value:size];
        return;
	}
	if (size < 65536) {
		[self addByte:lastFixSizeId + 2];
		[self writeInteger:2 value:size];
        return;
	}
    NSAssert(false, @"Size out of range: %d", size);
}

- (void)addString:(NSString *)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	[self writeSize:[data length] zeroSize:AGKArgosProtocolStringLen00 maxSize:AGKArgosProtocolStringLen0D];
	[[self currentData] appendData:data];
}

- (void)addSymbolToken:(NSUInteger)symbolId
{
	uint8_t symbolSingleTokenMax = AGKArgosProtocolSymbolId2D - AGKArgosProtocolSymbolId00;
	
    if (symbolId <= symbolSingleTokenMax) {
		[self addByte:(uint8_t)(symbolId + AGKArgosProtocolSymbolId00)];
        return;
	}

    [self addByte:AGKArgosProtocolSymbol2Eto12D];
    [self addByte:(uint8_t)(symbolId - symbolSingleTokenMax - 1)];
}

- (void)addSymbol:(NSString *)symbol
{
	if ([symbol length] > MaxSymbolLength) 
	{
		[self addString:symbol];
		return;
	}
	NSNumber *symbolId = [[self symbolList] objectForKey:symbol];
	if (symbolId) {
		[self addSymbolToken:[symbolId unsignedIntegerValue]];
		return;
	}
    
	NSUInteger symbols = [[self symbolList] count];
    
	if (symbols == [self maxSymbols]) {
		[self addString:symbol];
		return;
	}
    
	[self addSymbolToken:symbols];
	[[self symbolList] setObject:N(symbols) forKey:symbol];
    NSData *data = [symbol dataUsingEncoding:NSUTF8StringEncoding];
    [self writeInteger:1 value:[data length]];
    [[self currentData] appendData:data];
}

- (void)addBool:(BOOL)boolValue
{
	[self addByte:boolValue ? AGKArgosProtocolTrue : AGKArgosProtocolFalse];
}

- (void)addList:(NSArray *)list
{
	[self writeSize:[list count] zeroSize:AGKArgosProtocolArrayLen00 maxSize:AGKArgosProtocolArrayLen0D];
	for (id object in list) {
		[self add:object];
	}
}

- (void)addData:(NSData *)data
{
	[self writeSize:[data length] zeroSize:AGKArgosProtocolByteArrayLen00 maxSize:AGKArgosProtocolByteArrayLen0D];
	[[self currentData] appendData:data];
}

- (void)addDictionary:(NSDictionary *)dictionary
{
	[self writeSize:[dictionary count] zeroSize:AGKArgosProtocolMapLen00 maxSize:AGKArgosProtocolMapLen0D];
	for (id key in [dictionary allKeys]) {
		if ([key isKindOfClass:[NSString class]]) {
			[self addSymbol:key];
		} else {
			[self add:key];
		}
		[self add:[dictionary objectForKey:key]];
	}
}

- (void)addDate:(NSDate *)date
{
	int64_t time = llround([date timeIntervalSince1970] * 1000);
	if (time % 1000 != 0) {
		[self addByte:AGKArgosProtocolDateMilliseconds];
		[self writeInteger:8 value:time];
		return;
	}
	time /= 1000;
	if (time % 3600 != 0)
	{
		[self addByte:AGKArgosProtocolDateSeconds];
		[self writeInteger:5 value:time];
		return;
	}
	time /= 3600;
	[self addByte:AGKArgosProtocolDateHours];
	[self writeInteger:3 value:time];
}

- (void)add:(id)object
{
	if (object == nil || object == [NSNull null]) {
		[self addByte:AGKArgosProtocolNull];
	}
	else if ([object isKindOfClass:[NSNumber class]])
	{
		const char *type = [object objCType];
		switch (*type)
		{
			case 'c':
				[self addBool:[object boolValue]];
				break;
			case 'd':
			case 'f':
				[self addDouble:[object doubleValue]];
				break;
			default:
				[self addInteger:[object longLongValue]];
		}
	}
	else if ([object isKindOfClass:[NSString class]])
	{
		[self addString:object];
	}
	else if ([object isKindOfClass:[NSArray class]])
	{
		[self addList:object];
	}
	else if ([object isKindOfClass:[NSDictionary class]])
	{
		[self addDictionary:object];
	}
	else if ([object isKindOfClass:[NSData class]])
	{
		[self addData:object];
	}
	else if ([object isKindOfClass:[NSDate class]])
	{
		[self addDate:object];
	}
	else 
	{
		NSAssert1(false, @"Illegal object for serialization %@", object);
	}
}

- (void)reset
{
	[self setCurrentData:[[NSMutableData alloc] init]];	
}


- (NSData *)serialize
{
    NSData *data = [self currentData];
    [self setCurrentData:nil];
    return data;
}

- (NSData *)serialize:(NSObject *)object
{
	[self reset];
	[self add:object];
	return [self serialize];
}

@end

@implementation AGKArgosDeserializer

@synthesize symbolList = _symbolList, stream = _stream;

- (id)init
{
	if ((self = [super init])) {
		NSUInteger maxSymbols = AGKArgosProtocolSymbolId2D - AGKArgosProtocolSymbolId00 + 1 + 256;
		_symbolList = [[NSMutableDictionary alloc] initWithCapacity:maxSymbols];
	}
	return self;
}

- (uint8_t)readByte
{
    // Ignore EOF
    return (uint8_t)[_stream readByte];
}
- (NSNumber *)readOneByteInteger
{
	uint8_t value = [self readByte];
	return [NSNumber numberWithInt:(value >= 128 ? (int8_t)value : value + 128)];
}

- (uint64_t)readUnsignedInteger:(int)bytes
{
	uint64_t value = 0;
	for (int i = 0; i < bytes; i++) {
        value = value << 8 | [self readByte];
    }
	return value;
}

- (NSNumber *)readInteger:(int)bytes
{
	NSAssert(bytes > 0, @"Zero or less bytes read %d", bytes);
	int64_t value = (int64_t)[self readUnsignedInteger:bytes];
	if (bytes < 8) {
		long long max = (1LL << (8 * bytes - 1)) - 1;
		if (value > max) {
			value = (-1LL << (bytes * 8)) + value;
		}
	}
	return [NSNumber numberWithLongLong:value];
}

- (NSNumber *)readDouble
{
	uint64_t unsignedLong = [self readUnsignedInteger:8];
	double *d = (double *)&unsignedLong;
	return [NSNumber numberWithDouble:*d];
}

- (NSString *)readString:(uint64_t)length
{
    return [[self stream] readStringLength:(NSUInteger)length];
}

- (NSArray *)readList:(uint64_t)length
{
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:(NSUInteger) length];
	for (NSUInteger i = 0; i < length; i++) {
        id object = [self deserialize];
        [array addObject:object ? object : [NSNull null]];
	}
	return array;
}

- (NSString *)readSymbol:(uint64_t)symbolId
{
	id key = [NSNumber numberWithInt:(int)symbolId];
	NSString *symbol = [[self symbolList] objectForKey:key];
	if (symbol == nil) {
		NSUInteger length = (NSUInteger)[self readUnsignedInteger:1];
		symbol = [[self stream] readStringLength:length];
		[[self symbolList] setObject:symbol forKey:key];
	}
	return symbol;
}

- (NSData *)readData:(uint64_t)length
{
	return [[self stream] readDataLength:(NSUInteger)length];
}

- (NSDictionary *)readDictionary:(uint64_t)length
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:(NSUInteger) length];
	for (NSUInteger i = 0; i < length; i++)
	{
		id key = [self deserialize];
		id value = [self deserialize];
		[dictionary setObject:value forKey:key];
	}
	return dictionary;
}

- (id)deserialize
{
    if (![[self stream] hasData]) return nil;
    uint8_t value = [self readByte];
	switch (value) 
	{
		case AGKArgosProtocolNull:
			return nil;
		case AGKArgosProtocolMinusOne:
			return [NSNumber numberWithInt:-1];
		case AGKArgosProtocolDoubleZero:
			return [NSNumber numberWithDouble:0.0];
		case AGKArgosProtocolDouble:
			return [self readDouble];
		case AGKArgosProtocol1ByteInteger:
			return [self readOneByteInteger];
		case AGKArgosProtocolStringVar255:
        	return [self readString:[self readUnsignedInteger:1]];
		case AGKArgosProtocolStringVar65535:
			return [self readString:[self readUnsignedInteger:2]];
		case AGKArgosProtocolFalse:
			return [NSNumber numberWithBool:NO];
		case AGKArgosProtocolTrue:
			return [NSNumber numberWithBool:YES];
		case AGKArgosProtocolArrayVar255:
			return [self readList:[self readUnsignedInteger:1]];
		case AGKArgosProtocolArrayVar65535:
			return [self readList:[self readUnsignedInteger:2]];
		case AGKArgosProtocolMapVar255:
			return [self readDictionary:[self readUnsignedInteger:1]];
		case AGKArgosProtocolMapVar65535:
			return [self readDictionary:[self readUnsignedInteger:2]];
		case AGKArgosProtocolSymbol2Eto12D:
			return [self readSymbol:[self readUnsignedInteger:1] + AGKArgosProtocolSymbol2Eto12D - AGKArgosProtocolSymbolId00];
		case AGKArgosProtocolByteArrayVar255:
			return [self readData:[self readUnsignedInteger:1]];
		case AGKArgosProtocolByteArrayVar65535:
			return [self readData:[self readUnsignedInteger:2]];
		case AGKArgosProtocolDateHours:
			return [NSDate dateWithTimeIntervalSince1970:[[self readInteger:3] doubleValue] * 3600.0];
		case AGKArgosProtocolDateSeconds:
			return [NSDate dateWithTimeIntervalSince1970:[[self readInteger:5] doubleValue]];
		case AGKArgosProtocolDateMilliseconds:
			return [NSDate dateWithTimeIntervalSince1970:[[self readInteger:8] doubleValue] / 1000.0];
	}
	if (value <= AGKArgosProtocolInt7F)
	{
		return [NSNumber numberWithUnsignedChar:value - AGKArgosProtocolInt00];
	}
	if (value >= AGKArgosProtocol1ByteInteger && value <= AGKArgosProtocol8BytesInteger)
	{
		return [self readInteger:value - AGKArgosProtocol1ByteInteger + 1];
	}
	if (value >= AGKArgosProtocolStringLen00 && value <= AGKArgosProtocolStringLen0D)
	{
		return [self readString:value - AGKArgosProtocolStringLen00];
	}
	if (value >= AGKArgosProtocolArrayLen00 && value <= AGKArgosProtocolArrayLen0D)
	{
		return [self readList:value - AGKArgosProtocolArrayLen00];
	}
	if (value >= AGKArgosProtocolMapLen00 && value <= AGKArgosProtocolMapLen0D)
	{
		return [self readDictionary:value - AGKArgosProtocolMapLen00];
	}
	if (value >= AGKArgosProtocolSymbolId00 && value <= AGKArgosProtocolSymbolId2D)
	{
		return [self readSymbol:value - AGKArgosProtocolSymbolId00];
	}
	if (value >= AGKArgosProtocolByteArrayLen00 && value <= AGKArgosProtocolByteArrayLen0D)
	{
		return [self readData:value - AGKArgosProtocolByteArrayLen00];
	}
	NSAssert(NO, @"Illegal code %x during deserialization", value);
	return nil;
}

- (id)deserializeStream:(AGKDataInputStream *)stream
{
    [self setStream:stream];
	id result = [self deserialize];
    [self setStream:nil];
    return result;
}

- (id)deserialize:(NSData *)data
{
    return [self deserializeStream:[[AGKDataInputStream alloc] initWithData:data]];
}

@end