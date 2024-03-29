//
//  AGKSecurity.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-27-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Security/Security.h>
#import "AGKSecurity.h"
#import "AGK.h"
#import "NSData+Extras.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonKeyDerivation.h>

@interface RSAKey() {}
@property (nonatomic, assign) SecKeyRef secKey;
- (size_t)maxDecryptedSize;
@end

@implementation RSAKey
@synthesize secKey = _secKey;


- (id)initWithData:(NSData *)data
{
    if ((self = [super init])) {
                
        /* Load as a key ref */
        CFTypeRef persistPeer = NULL;
        char *refString = "DummyKey";
        
        NSData *refTag = [[NSData alloc] initWithBytes:refString length:strlen(refString)];
        NSMutableDictionary *keyAttr = [[NSMutableDictionary alloc] init];
        
        [keyAttr setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [keyAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
        [keyAttr setObject:refTag forKey:(__bridge id)kSecAttrApplicationTag]; 
        
        /* First we delete any current keys */
        SecItemDelete((__bridge CFDictionaryRef) keyAttr);
        
        [keyAttr setObject:[data stripJavaRSAKey] forKey:(__bridge id)kSecValueData];
        [keyAttr setObject:B(YES) forKey:(__bridge id)kSecReturnPersistentRef];
        
        if (SecItemAdd((__bridge CFDictionaryRef) keyAttr, (CFTypeRef *)&persistPeer) != errSecSuccess) {
            NSLog(@"Failed to add public key to keychain");
            self = nil;
            return nil;
        }
                
        CFRelease(persistPeer);
        
        SecKeyRef publicKeyRef = nil;
        
        [keyAttr removeAllObjects];
        [keyAttr setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
        [keyAttr setObject:refTag forKey:(__bridge id)kSecAttrApplicationTag];
        [keyAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
        [keyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
        
        // Get the persistent key reference.
        if (SecItemCopyMatching((__bridge CFDictionaryRef)keyAttr, (CFTypeRef *)&publicKeyRef) != errSecSuccess) {
            NSLog(@"Failed to retrieve added public key");
            self = nil;
            return nil;
        }
        
        _secKey = publicKeyRef;
    }
    
    return self;
}

- (size_t)byteSize
{
    return SecKeyGetBlockSize([self secKey]);
}

- (size_t)maxDecryptedSize
{
    return [self byteSize] - 11;
}

- (size_t)maxEncryptedSize
{
    return [self byteSize];
}

- (void)dealloc
{
    if (_secKey) CFRelease(_secKey);
}

@end

@implementation NSData (AGKSecurity)

- (NSData *)stripJavaRSAKey
{
    // Stripp ASN courtesey of http://blog.wingsofhermes.org/
    
    /* Now strip the uncessary ASN encoding guff at the start */
    uint8_t * bytes = (unsigned char *)[self bytes];
    size_t bytesLen = [self length];
    
    /* Strip the initial stuff */
    size_t i = 0;
    if (bytes[i++] != 0x30)
        return FALSE;
    
    /* Skip size bytes */
    if (bytes[i] > 0x80) {
        i += bytes[i] - 0x80 + 1;            
    } else {
        i++;
    }
    
    if (i >= bytesLen) return nil;
    
    if (bytes[i] != 0x30) return nil;
    
    /* Skip OID */
    i += 15;
    
    if (i >= bytesLen - 2) return nil;
    
    if (bytes[i++] != 0x03) return nil;
    
    /* Skip length and null */
    if (bytes[i] > 0x80) {
        i += bytes[i] - 0x80 + 1;
    }
    else {
        i++;
    }
    
    if (i >= bytesLen) return nil;
    
    if (bytes[i++] != 0x00) return nil;

    if (i >= bytesLen) return nil;
    
    /* Here we go! */
    return [NSData dataWithBytes:&bytes[i] length:bytesLen - i];
}

- (NSData *)plainRsaEncrypt:(RSAKey *)key
{
    size_t requiredSize = [key maxEncryptedSize];
    if ([self length] != requiredSize) {
        NSLog(@"Failed encryption, data does not match key size");
        return nil;
    }
    uint8_t *encryptedData = calloc(requiredSize, sizeof(uint8_t));
    size_t cipherLength = requiredSize;
    NSData *result = nil;
    OSStatus status = SecKeyEncrypt([key secKey], kSecPaddingNone, (const uint8_t *)[self bytes], [self length], encryptedData, &cipherLength);
    if (cipherLength != requiredSize) {
        NSLog(@"Encryption surprisingly changed output size");
        free(encryptedData);
        return nil;
    }
    if (status == noErr) {
        result = [[NSData alloc] initWithBytes:encryptedData length:requiredSize];
    } else {
        NSLog(@"Failed encryption %ld %d", status, [self length]);
    }
    free(encryptedData);
    return result;
}

- (NSData *)rsaEncrypt:(RSAKey *)key
{
    if ([self length] > [key maxDecryptedSize]) {
        NSLog(@"Failed encryption, data too long");
        return nil;
    }
    uint8_t *encryptedData = calloc([key maxEncryptedSize], sizeof(uint8_t));
    size_t cipherLength = [key maxEncryptedSize];
    NSData *result = nil;
    OSStatus status = SecKeyEncrypt([key secKey], kSecPaddingOAEP, (const uint8_t *)[self bytes], [self length], encryptedData, &cipherLength);
    if (status == noErr) {
        result = [[NSData alloc] initWithBytes:encryptedData length:cipherLength];
    } else {
        NSLog(@"Failed encryption %ld %d", status, [self length]);
    }
    free(encryptedData);
    return result;
}

- (NSData *)rsaEncryptWithSha256:(RSAKey *)key
{
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:32 + [self length]];
    [data appendData:[self sha256]];
    [data appendData:self];
    return [data rsaEncrypt:key];
}

- (NSData *)hmacSHA256:(NSData *)signKey, ...
{
    CCHmacContext context;
    CCHmacInit(&context, kCCHmacAlgSHA256, [signKey bytes], [signKey length]);
    CCHmacUpdate(&context, [self bytes], [self length]);
    va_list list;
    va_start(list, signKey);
    void *aData = nil;
    while ((aData = va_arg(list, void *)) != nil) {
        CCHmacUpdate(&context, [(__bridge NSData *)aData bytes], [(__bridge NSData *)aData length]);
    }
    uint8_t *mac = malloc(CC_SHA256_DIGEST_LENGTH);
    CCHmacFinal(&context, mac);
    return [[NSData alloc] initWithBytesNoCopy:mac length:8 freeWhenDone:YES];
}

- (NSData *)sha256
{
    CC_SHA256_CTX sha;
    unsigned char result[32];
    CC_SHA256_Init(&sha);
    CC_SHA256_Update(&sha, [self bytes], [self length]);
    CC_SHA256_Final(result, &sha);
    return [[NSData alloc] initWithBytes:result length:32];
}

- (NSData *)sha256PBKDF2KeyWithSalt:(NSString *)salt iterations:(NSUInteger)iterations length:(NSUInteger)length;
{
    return [self pbkdf2KeyWithAlgorithm:kCCPRFHmacAlgSHA256 salt:salt iterations:iterations length:length];
}
            
- (NSData *)pbkdf2KeyWithAlgorithm:(CCHmacAlgorithm)algorithm salt:(NSString *)salt iterations:(NSUInteger)iterations length:(NSUInteger)length
{
    NSData *saltData = [salt dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t *derivedKey = (uint8_t *)malloc(length);
    int result = CCKeyDerivationPBKDF(kCCPBKDF2, [self bytes], [self length], [saltData bytes], [saltData length], algorithm, iterations, derivedKey, length);
    if (result != noErr) {
        NSLog(@"Error in key derivation: %d", result);
        return nil;
    }
    return [[NSData alloc] initWithBytesNoCopy:derivedKey length:length freeWhenDone:YES];
}

- (NSData *)aesEncrypt:(NSData *)key iv:(NSData **)ivReturned
{
    uint8_t *ivBytes = malloc(16);
    SecRandomCopyBytes(kSecRandomDefault, 16, ivBytes);
    *ivReturned = [NSData dataWithBytesNoCopy:ivBytes length:16 freeWhenDone:YES]; 
    return [self aesCrypt:key iv:ivBytes encrypt:YES];
}

- (NSData *)aesDecrypt:(NSData *)key iv:(NSData *)iv
{
    return [self aesCrypt:key iv:(uint8_t *)[iv bytes] encrypt:NO];
}

- (NSData *)aesCrypt:(NSData *)key iv:(uint8_t *)iv encrypt:(BOOL)encrypt
{
    size_t bufferSize = [self length] + kCCBlockSizeAES128;
    size_t decryptedLength = 0;
    uint8_t *destinationBuffer = malloc(bufferSize);
    CCCryptorStatus ccStatus = CCCrypt(encrypt ? kCCEncrypt : kCCDecrypt, 
                                       kCCAlgorithmAES128,
                                       kCCOptionPKCS7Padding,
                                       [key bytes],
                                       [key length],
                                       iv,
                                       [self bytes],
                                       [self length],
                                       destinationBuffer,
                                       bufferSize,
                                       &decryptedLength);
    if (ccStatus != kCCSuccess) {
        AGKLog(encrypt ? @"Encryption failed: %d" : @"Decryption failed %d", ccStatus);
        free(destinationBuffer);
        return nil;
    }
    return [[NSData alloc] initWithBytesNoCopy:destinationBuffer length:decryptedLength freeWhenDone:YES];
}

- (NSData *)aesDecryptUsingKey:(NSData *)key sha256SignedUsing:(NSData *)signedKey
{
    NSData *hmac = [self subdataWithRange:NSMakeRange(0, 8)];
    NSData *iv = [self subdataWithRange:NSMakeRange([self length] - 16, 16)];
    NSData *encryptedData = [self subdataWithRange:NSMakeRange(8, [self length] - 24)];
    NSData *hmacControl = [iv hmacSHA256:signedKey, encryptedData, nil];
    if (![hmacControl isEqualToData:hmac]) {
        AGKTrace(@"Mac mismatch %@ vs %@", hmac, hmacControl);
        return nil;
    }
    return [encryptedData aesDecrypt:key iv:iv];
}

- (NSData *)aesEncryptUsingKey:(NSData *)key sha256SignedUsing:(NSData *)signedKey
{
    NSData *iv = nil;
    NSData *encryptedData = [self aesEncrypt:key iv:&iv];
    NSData *hmac = [iv hmacSHA256:signedKey, encryptedData, nil];
    return [NSData dataWithDatas:hmac, encryptedData, iv, nil];
}

@end
