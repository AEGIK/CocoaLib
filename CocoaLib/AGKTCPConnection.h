//
//  AGKTCPConnection.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-24-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AGKTCPConnection;

@protocol AGKTCPConnectionReader<NSObject>
- (NSData *)assemblePacket:(NSData *)data;
@end

@protocol AGKTCPConnectionWriter<NSObject>
- (NSData *)prependData:(NSData *)data;
- (NSData *)appendData:(NSData *)data;
- (NSData *)transformData:(NSData *)data;
@end

@interface AGKTCPConnectionStandardReader : NSObject<AGKTCPConnectionReader> 
- (id)initWithHeaderSize:(NSUInteger)headerSize;
@end

@interface AGKTCPConnectionStandardWriter : NSObject<AGKTCPConnectionWriter> 
- (id)initWithHeaderSize:(NSUInteger)headerSize;
@end

typedef enum AGKTCPConnectionClose
{
    AGKTCPConnectionCloseUserClosed,
    AGKTCPConnectionCloseConnectionTimeout,
    AGKTCPConnectionCloseStreamError,
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
- (id)initWithHost:(NSString *)host port:(NSUInteger)port;
- (void)open;
- (void)sendData:(NSData *)data;
- (NSString *)hostPortDescription;

@property (nonatomic, weak) NSObject<AGKTCPConnectionDelegate> *delegate;
@property (nonatomic, assign, readonly, getter = isOpen) BOOL open;
@property (nonatomic, assign, readonly, getter = isConnected) BOOL connected;
@property (nonatomic, strong, readonly) NSString *host;
@property (nonatomic, assign, readonly) NSUInteger port;
@property (nonatomic, strong) NSObject<AGKTCPConnectionReader> *reader;
@property (nonatomic, strong) NSObject<AGKTCPConnectionWriter> *writer;
@end
