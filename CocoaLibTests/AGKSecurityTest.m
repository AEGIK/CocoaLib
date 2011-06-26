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

@end
