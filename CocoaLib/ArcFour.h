//
//  ArcFour.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-13-02.
//  Copyright 2011 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArcFour : NSObject {
}

- (ArcFour *)initWithKey:(NSData *)key;
+ (NSData *)createHashUsingSha1:(NSData *)value1 value2:(NSData *)value2;
- (NSData *)encrypt:(NSData *)data;
- (NSData *)decrypt:(NSData *)data;

@end
