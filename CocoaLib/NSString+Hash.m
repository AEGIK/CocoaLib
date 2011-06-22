//
//  NSString+Hash.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-27-09.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSString+Hash.h"
#import "NSString+Extras.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString(Hash)

- (NSString *)sha256:(NSUInteger)passes withSalt:(NSString *)salt {
	CC_SHA256_CTX sha;
	const char *currentString = [self UTF8String];
	const char *saltBytes = [salt UTF8String];
	size_t saltLen = strlen(saltBytes);
	size_t currentLen = strlen(currentString);
	unsigned char result[32];
	char hash[65];
	hash[64] = 0;
	for (NSUInteger i = 0; i < passes; i++) {
		CC_SHA256_Init(&sha);
		CC_SHA256_Update(&sha, currentString, currentLen);
		CC_SHA256_Update(&sha, saltBytes, saltLen);
		CC_SHA256_Final(result, &sha);
		bytesToHex(result, hash, 32);
		currentString = hash;
		currentLen = 64;
	}
	return [NSString stringWithCString:hash encoding:NSASCIIStringEncoding];
}

- (NSString *)md5 {
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	const char *cString = [self UTF8String];
    CC_MD5(cString, strlen(cString), result);
	return bytesToHexString(result, CC_MD5_DIGEST_LENGTH);
}
@end
