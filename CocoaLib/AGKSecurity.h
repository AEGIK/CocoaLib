//
//  AGKSecurity.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-27-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSAKey : NSObject {}
- (id)initWithData:(NSData *)data;
@end

@interface NSData (AGKSecurity)
- (NSData *)stripJavaRSAKey;
- (NSData *)rsaEncrypt:(RSAKey *)key;
- (NSData *)rsaEncryptWithSha256:(RSAKey *)key;
- (NSData *)sha256;
@end

