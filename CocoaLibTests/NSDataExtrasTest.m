//
//  NSDataExtrasTest.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-28-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import "NSDataExtrasTest.h"

@implementation NSDataExtrasTest

- (void)testDataMerge
{
    NSData *data1 = [NSData dataWithDatas:[@"test" dataUsingEncoding:NSASCIIStringEncoding], [@"test2" dataUsingEncoding:NSASCIIStringEncoding], [@"test3" dataUsingEncoding:NSASCIIStringEncoding], nil];
    NSData *data1Ref = [@"testtest2test3" dataUsingEncoding:NSASCIIStringEncoding];
    STAssertEqualObjects(data1, data1Ref, @"Three args %@ %@", data1, data1Ref);
    NSData *data2 = [NSData dataWithDatas:[@"test" dataUsingEncoding:NSASCIIStringEncoding], [@"test2" dataUsingEncoding:NSASCIIStringEncoding], nil];
    NSData *data2Ref = [@"testtest2" dataUsingEncoding:NSASCIIStringEncoding];
    STAssertEqualObjects(data2, data2Ref, @"Two args");
    NSData *data3 = [NSData dataWithDatas:[@"test" dataUsingEncoding:NSASCIIStringEncoding], nil];
    NSData *data3Ref = [@"test" dataUsingEncoding:NSASCIIStringEncoding];
    STAssertEqualObjects(data3, data3Ref, @"One arg");
}

- (void)testWrite
{
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:100];
    [data writeByte:0xFF];
    [data writeBigEndianShort:0xFEDC];
    [data writeBigEndianInteger:0xFEDCBA99];
    [data writeBigEndianLong:0x1234567890ABCDEF];
    NSData *ref = [NSData dataWithHexString:@"FFFEDCFEDCBA991234567890ABCDEF"];
    STAssertEqualObjects(data, ref, @"Write should match");
    
}
@end
