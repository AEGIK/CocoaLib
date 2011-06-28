//
//  AGKSecurityTest.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-27-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AGKSecurityTest.h"
#import "AGKSecurity.h"
#import "NSData+Extras.h"

@implementation AGKSecurityTest

- (void)testRSAEncrypt
{
    RSAKey *key = [[RSAKey alloc] initWithData:[NSData dataWithHexString:@"305C300D06092A864886F70D0101010500034B0030480241009690168E66FE18B3B39CA726213F54C405A770061E251A1ED5906BCB129028DC7AC5F8D52C159BA923B4E9514EFCA7DDE372062A7738B56D5DDE480AAE290F5B0203010001"]];
    NSData *data = [[@"test" dataUsingEncoding:NSUTF8StringEncoding] rsaEncryptWithSha256:key];
    NSLog(@"%@ %@", data, key);
}

- (void)testKeyGen
{
    NSData *data = [NSData dataWithHexString:@"348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c"];
    NSData *key = [[@"passwordPASSWORDpassword" dataUsingEncoding:NSASCIIStringEncoding] sha256PBKDF2KeyWithSalt:@"saltSALTsaltSALTsaltSALTsaltSALTsalt"
                                                                                                      iterations:4096
                                                                                                          length:25];
    STAssertEqualObjects(data, key, @"Keygen failed");
}

- (void)testAESDecrypt
{
    NSData *iv = HEXDATA("000102030405060708090A0B0C0D0E0F");
    NSData *key = [NSData dataWithHexString:@"603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4"];
    NSData *encryptedData = [NSData dataWithHexString:@"abbebef2d0030b9fa9cce2b3655102dc"];
    NSData *decryptedData = [encryptedData aesDecrypt:key iv:iv]; 
    STAssertEqualObjects(decryptedData, [@"encrypt me" dataUsingEncoding:NSASCIIStringEncoding], @"Decrypt failed");
    NSData *someData = [@"encrypt silly little me" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *newIV = nil;
    encryptedData = [someData aesEncrypt:key iv:&newIV];
    decryptedData = [encryptedData aesDecrypt:key iv:newIV];
    STAssertEqualObjects(decryptedData, someData, @"Encrypt failed");
}
- (void)testAESDecryptSHA256Signed
{
    NSData *key = HEXDATA("95C76B058A4B8B01D07492A19B275A9413C366B48D113CA142570FF178A16E56");
    NSData *signKey = HEXDATA("63AB0DB9E1AEB15826271754F759848866D976AF5BDF93DB9F94A48520544853");
    NSData *encryptedData = HEXDATA("6085A5639341210ADA49A5976B18B694CF242FE14E71880995DD740DF94ECB65B1E19CE359D9CB32");
    NSData *expectedResult = [@"FOOBAR" dataUsingEncoding:NSUTF8StringEncoding];
    STAssertEqualObjects(expectedResult, [encryptedData aesDecryptUsingKey:key sha256SignedUsing:signKey], @"Should match");
    STAssertEqualObjects(expectedResult, [[expectedResult aesEncryptUsingKey:key sha256SignedUsing:signKey] aesDecryptUsingKey:key sha256SignedUsing:signKey], @"Should match");
}
@end
