//
//  NSString+Hash.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-27-09.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(Hash)
- (NSString *)sha256:(NSUInteger)passes withSalt:(NSString *)string;
- (NSString *)md5;
@end
