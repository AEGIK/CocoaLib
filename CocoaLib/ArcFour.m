//
//  ArcFour.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-13-02.
//  Copyright 2011 Aegik AB. All rights reserved.
//

#import "ArcFour.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>

@interface ArcFour() {
    CCCryptorRef encryptor;
	CCCryptorRef decryptor;
	uint8_t* encryptionBuffer;
}
@end


static const NSUInteger EncryptionSize = 128;
static const NSUInteger BufferSize = 1024 * 128;

@implementation ArcFour

+ (NSData *)createHashUsingSha1:(NSData *)value1 value2:(NSData *)value2 {
	static const uint8_t nonce[] = { 0x6f, 0x9c, 0x9e, 0x65, 0x76, 0x43, 0x4c };
    
	// Create sha1 of the correct length.
	CC_SHA1_CTX ctx;
	uint8_t hashBytes[CC_SHA1_DIGEST_LENGTH];
	
	// Initialize the context.
    CC_SHA1_Init(&ctx);
    
	// Perform the hash.
    CC_SHA1_Update(&ctx, [value1 bytes], [value1 length]);
    CC_SHA1_Update(&ctx, [value2 bytes], [value2 length]);
	CC_SHA1_Update(&ctx, nonce, 7);
	
	// Finalize the output.
    CC_SHA1_Final(hashBytes, &ctx);
    
    // Build up the SHA1 blob.
    NSData *key = [NSData dataWithBytes:hashBytes length:CC_SHA1_DIGEST_LENGTH];	
    return key;	
}

- (id)initWithKey:(NSData *)key {
	if ((self = [super init])) {
		CCCryptorStatus ccStatus = CCCryptorCreate(kCCEncrypt, 
												   kCCAlgorithmRC4, 
												   0,
												   (const void *)[key bytes], 
												   [key length], 
												   NULL, 
												   &encryptor);
		if (ccStatus != kCCSuccess) {
			NSAssert(false, @"Failed to create encryptor");
			return nil;
		}
		ccStatus = CCCryptorCreate(kCCDecrypt, 
								   kCCAlgorithmRC4, 
								   0,
								   (const void *)[key bytes], 
								   [key length], 
								   NULL, 
								   &decryptor);
		if (ccStatus != kCCSuccess) {
			NSAssert(false, @"Failed to create decryptor");
			return nil;
		}
		encryptionBuffer = calloc(BufferSize, sizeof(uint8_t));
//		NSData *data = [NSData dataWithBytes:encryptionBuffer length:512];
//		[self decrypt:[self encrypt:data]];
	}
	return self;
}

- (NSData *)encrypt:(NSData *)data {
	size_t dataEncrypted;
	
	CCCryptorUpdate(encryptor, 
					[data bytes],
					[data length],
					encryptionBuffer,
					BufferSize,
					&dataEncrypted);
	if (dataEncrypted == 0) return nil;
	return [NSData dataWithBytes:encryptionBuffer length:dataEncrypted];
}

- (NSData *)decrypt:(NSData *)data {
    
	size_t dataDecrypted;
	
	CCCryptorUpdate(decryptor, 
					[data bytes],
					[data length],
					encryptionBuffer,
					BufferSize,
					&dataDecrypted);
	
    if (dataDecrypted == 0) return nil;
	return [NSData dataWithBytes:encryptionBuffer length:dataDecrypted];
}

- (void)dealloc {
	if (encryptor) CCCryptorRelease(encryptor);
	if (decryptor) CCCryptorRelease(decryptor);
	if (encryptionBuffer) free(encryptionBuffer);
}
@end
