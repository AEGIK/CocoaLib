//
//  AGKTests.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-12-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import "AGKTests.h"
#import "AGK.h"

@implementation AGKTests

- (void)testMacros 
{
    STAssertEqualObjects(N(201), [NSNumber numberWithInteger:201], @"Numbers should match");    
    STAssertEqualObjects(B(YES), [NSNumber numberWithBool:YES], @"Bools should match");
    STAssertEqualObjects(B(NO), [NSNumber numberWithBool:NO], @"Bools should match");
    STAssertEqualObjects(N(0xFFFFFFFFFFFF), [NSNumber numberWithLongLong:0xFFFFFFFFFFFF], @"Numbers should match");    
    STAssertEqualObjects(N(-0xFFFFFFFFFFFF), [NSNumber numberWithLongLong:-0xFFFFFFFFFFFF], @"Numbers should match");    
    STAssertEqualObjects(F(1920.12091201), [NSNumber numberWithDouble:1920.12091201], @"Floats should match");
}

@end
