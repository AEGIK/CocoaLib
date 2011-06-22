//
//  NSString+URLEncode.h
//  FCJ
//
//  Created by Christoffer Lernö on 2010-04-03.
//  Copyright 2010 Millennium Monkey. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(URLEncode)
-(NSString *)urlEncode;
- (NSString *)urlDecode;
@end
