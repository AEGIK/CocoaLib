//
//  AGKSecurity.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-27-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonKeyDerivation.h>

@interface RSAKey : NSObject {}
- (id)initWithData:(NSData *)data;
@end

@interface NSData (AGKSecurity)
- (NSData *)stripJavaRSAKey;
- (NSData *)aesCrypt:(NSData *)key iv:(uint8_t *)iv encrypt:(BOOL)encrypt;
- (NSData *)aesEncrypt:(NSData *)key iv:(NSData **)iv;
- (NSData *)aesDecrypt:(NSData *)key iv:(NSData *)iv;
- (NSData *)aesDecryptUsingKey:(NSData *)key sha256SignedUsing:(NSData *)signedKey;
- (NSData *)aesEncryptUsingKey:(NSData *)key sha256SignedUsing:(NSData *)signedKey;
- (NSData *)rsaEncrypt:(RSAKey *)key;
- (NSData *)rsaEncryptWithSha256:(RSAKey *)key;
- (NSData *)hmacSHA256:(NSData *)signKey, ... NS_REQUIRES_NIL_TERMINATION;
- (NSData *)sha256;
- (NSData *)pbkdf2KeyWithAlgorithm:(CCHmacAlgorithm)algorithm salt:(NSString *)salt iterations:(NSUInteger)iterations length:(NSUInteger)length;
- (NSData *)sha256PBKDF2KeyWithSalt:(NSString *)salt iterations:(NSUInteger)iterations length:(NSUInteger)length;
@end

