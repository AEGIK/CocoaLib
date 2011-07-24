//
//  AGKArgosConnection.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-24-07.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AGKTCPConnection.h"

typedef enum AGKArgosConnectionClose
{
    AGKArgosConnectionCloseProtocolError,
    AGKArgosConnectionCloseConnectionTimeout,
    AGKArgosConnectionCloseConnectionClosed,
    AGKArgosConnectionCloseConnectionError,
} AGKArgosConnectionClose;

@protocol AGKArgosConnectionDelegate<NSObject>
- (void)connectionLost:(AGKArgosConnectionClose)closeReason;
- (void)receivedPacket:(NSUInteger)packet payload:(id)payload;
@end

@class RSAKey;

NSString *AGKArgosConnectionCloseToLocalizedString(AGKArgosConnectionClose reason);

@interface AGKArgosConnection : NSObject<AGKTCPConnectionDelegate>

- (void)close;
- (void)closeAfterWrite;
- (id)initWithHost:(NSString *)host port:(NSUInteger)port key:(RSAKey *)key protocol:(NSUInteger)protocol;
- (void)open;
- (NSString *)hostPortDescription;
- (void)send:(NSUInteger)packet payload:(NSDictionary *)payload;

@property (nonatomic, weak) NSObject<AGKArgosConnectionDelegate> *delegate;
@property (nonatomic, assign, readonly, getter=isOpen) BOOL open;
@end
