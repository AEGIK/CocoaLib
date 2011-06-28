//
//  NSString+URLEncode.m
//  FCJ
//
//  Created by Christoffer Lernö on 2010-04-03.
//  Copyright 2010 Millennium Monkey. All rights reserved.
//

#import "NSString+URLEncode.h"


@implementation NSString(URLEncode)

-(NSString *)urlEncode
{
    return (__bridge_transfer NSString *)(CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self,
                                                                                  NULL,
                                                                                  (__bridge CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                  kCFStringEncodingUTF8));
}

- (NSString *)urlDecode 
{
	return [[self stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
