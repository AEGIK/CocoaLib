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
    NSString *encodedString = objc_retainedObject(CFURLCreateStringByAddingPercentEscapes(NULL, objc_unretainedPointer(self),
                                                                                          NULL,
                                                                                          (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                          kCFStringEncodingUTF8));
    return encodedString;
}

- (NSString *)urlDecode 
{
	return [[self stringByReplacingOccurrencesOfString:@"+" withString:@" "] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

@end
