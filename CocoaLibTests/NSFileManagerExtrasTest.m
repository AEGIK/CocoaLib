//
//  NSFileManagerExtrasTest.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-18-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import "NSFileManagerExtrasTest.h"
#import "NSFileManager+Extras.h"

@implementation NSFileManagerExtrasTest

- (void)testUserDir
{
    STAssertTrue([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) indexOfObject:[NSFileManager userDirectory:NSDocumentDirectory]] != NSNotFound, @"Directory not in list");
}

@end
