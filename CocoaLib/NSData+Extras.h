//
//  NSData+Extras.h
//  AGKCocoaLib
//
//  Created by Christoffer Lernö on 2011-15-02.
//  Copyright 2011 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData(Extras)
+ (NSData *)dataWithHexString:(NSString *)hexString;
+ (NSData *)dataWithDatas:(NSData *)data, ... NS_REQUIRES_NIL_TERMINATION;
- (NSData *)dataWithBigEndian16BitSizePrefix;

@end

@interface NSMutableData (Extras)
- (void)writeByte:(uint8_t)byte;
- (void)writeBigEndianShort:(uint16_t)aShort;
- (void)writeBigEndianInteger:(uint32_t)anInteger;
- (void)writeBigEndianLong:(uint64_t)aLong;
@end
