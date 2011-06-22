//
//  NSString+JSON.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-21-09.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(JSON)
- (NSDictionary *)jsonDecode;
@end

@interface NSData(JSON)
- (NSDictionary *)jsonDecode;
- (NSDictionary *)jsonDecode:(NSStringEncoding)encoding;
@end

