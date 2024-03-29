//
//  AGKDataInputStream.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-03-07.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AGKDataInputStream : NSObject

- (id)initWithData:(NSData *)data;
- (void)reset;
- (BOOL)hasData;
- (NSData *)readDataLength:(NSUInteger)length;
- (NSString *)readStringLength:(NSUInteger)length;
- (NSInteger)readByte;
- (NSInteger)readUnsignedShort;
- (NSData *)readVariable255Bytes;
- (NSData *)readVariable65535Bytes;
- (NSString *)readTinyString;
- (NSDate *)readMillisecondsSinceEpoch;
@end
