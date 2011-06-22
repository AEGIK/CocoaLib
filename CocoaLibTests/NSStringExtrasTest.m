//
//  NSStringExtrasTest.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-19-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import "NSStringExtrasTest.h"
#import "NSString+URLEncode.h"

@implementation NSStringExtrasTest

- (void)testURLEncodeDecode
{
    STAssertEqualObjects(@"A%20%C3%A5", [@"A å" urlEncode], @"Encoding failed");
    STAssertEqualObjects(@"A å", [[@"A å" urlEncode] urlDecode], @"Decoding failed");
}
@end
