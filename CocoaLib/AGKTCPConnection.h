//
//  AGKTCPConnection.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-24-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AGKTCPConnection;

typedef enum AGKTCPConnectionClose
{
    AGKTCPConnectionCloseUserClosed,
    AGKTCPConnectionCloseConnectionTimeout,
    AGKTCPConnectionCloseGeneralError,
    AGKTCPConnectionCloseStreamClosed,
} AGKTCPConnectionClose;

@protocol AGKTCPConnectionDelegate <NSObject>
@optional
- (void)connectionOpened:(AGKTCPConnection *)connection;
- (void)connection:(AGKTCPConnection *)connection receivedData:(NSData *)data;
- (void)connection:(AGKTCPConnection *)connection closed:(AGKTCPConnectionClose)closeReason;
@end

@interface AGKTCPConnection : NSObject
- (void)close;
- (void)closeAfterWrite;
- (id)initWithHost:(NSString *)url port:(NSUInteger)port;
- (void)open;
- (void)sendData:(NSData *)data;

@property (nonatomic, weak) NSObject<AGKTCPConnectionDelegate> *delegate;
@property (nonatomic, assign, readonly, getter = isOpen) BOOL open;
@property (nonatomic, assign, readonly, getter = isConnected) BOOL connected;
@end
