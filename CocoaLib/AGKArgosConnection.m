//
//  AGKArgosConnection.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-24-07.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import "AGKArgosConnection.h"
#import "AGK.h"
#import "AGKSecurity.h"
#import <Security/Security.h>
#import "AGKArgosSerialization.h"
#import "AGKDataInputStream.h"
#import "NSData+Extras.h"


NSString *AGKArgosConnectionCloseToLocalizedString(AGKArgosConnectionClose reason)
{
    switch (reason) {
        case AGKArgosConnectionCloseConnectionTimeout:
            return NSLocalizedString(@"Failed to get response from the server, check your internet connection and try again.", @"Connection timeout message");
        case AGKArgosConnectionCloseConnectionError:
            return NSLocalizedString(@"Connection to the server failed, check your internet connection and try again.", @"Connection error message");
        case AGKArgosConnectionCloseConnectionClosed:
            return NSLocalizedString(@"The server refused your request. Please try again later and contact support if the problem persists.", @"Connection refused message alert");
        case AGKArgosConnectionCloseProtocolError:
            return NSLocalizedString(@"The server response could not be understood. Please contact support to resolve the issue.", @"Sec breach error message");
        default:
            return NSLocalizedString(@"An unexpected error occurred", @"Unexpected error");
    }    
}

@interface AGKArgosConnection() {}
@property (nonatomic, strong) AGKTCPConnection *connection;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) NSUInteger port;
@property (nonatomic, strong) RSAKey *key;
@property (nonatomic, strong) NSData *clientToServerEncrypt;
@property (nonatomic, strong) NSData *clientToServerAuth;
@property (nonatomic, strong) NSData *serverToClientEncrypt;
@property (nonatomic, strong) NSData *serverToClientAuth;
@property (nonatomic, strong) AGKArgosSerializer *serializer;
@property (nonatomic, strong) AGKArgosDeserializer *deserializer;
@property (nonatomic, assign) NSUInteger outgoingMessageNumber;
@property (nonatomic, assign) NSUInteger incomingMessageNumber;
@property (nonatomic, assign, readwrite, getter=isOpen) BOOL open;
@property (nonatomic, strong) NSMutableArray *packetQueue;
@property (nonatomic, assign) NSUInteger protocol;
@end

@implementation AGKArgosConnection

@synthesize connection = _connection, host = _host, port = _port, key = _key;
@synthesize clientToServerAuth = _clientToServerAuth, clientToServerEncrypt = _clientToServerEncrypt;
@synthesize serverToClientAuth = _serverToClientAuth, serverToClientEncrypt = _serverToClientEncrypt;
@synthesize serializer = _serializer, deserializer = _deserializer, delegate = _delegate;
@synthesize incomingMessageNumber = _incomingMessageNumber, outgoingMessageNumber = _outgoingMessageNumber;
@synthesize open = _open, packetQueue = _packetQueue, protocol = _protocol;

- (id)initWithHost:(NSString *)host port:(NSUInteger)port key:(RSAKey *)key protocol:(NSUInteger)protocol
{
    if ((self = [super init])) {
        _host = host;
        _port = port;
        _key = key;
        _open = NO;
        _protocol = protocol;
    }
    return self;
}


- (void)open
{
    [_connection setDelegate:nil];
    _connection = [[AGKTCPConnection alloc] initWithHost:[self host] port:[self port]];
    [_connection setReader:[[AGKTCPConnectionStandardReader alloc] initWithHeaderSize:2]];
    [_connection setWriter:[[AGKTCPConnectionStandardWriter alloc] initWithHeaderSize:2]];
    [_connection setDelegate:self];
    [_connection open];
    [self setPacketQueue:nil];
    [self setSerializer:nil];
    [self setDeserializer:nil];
    [self setOpen:YES];
}

- (void)connectionOpened:(AGKTCPConnection *)connection
{
    [self setOutgoingMessageNumber:0];
    [self setIncomingMessageNumber:0];
    if (connection != [self connection]) return;
    uint8_t *bytes = malloc([[self key] byteSize]);
    SecRandomCopyBytes(kSecRandomDefault, [[self key] byteSize], bytes);
    bytes[0] = 0x00;
    bytes[1] = 0x02;
    // &= 0x00; // make sure that the top bits aren't set.
    NSData *data = [[NSData alloc] initWithBytes:bytes length:[[self key] byteSize]];
    free(bytes);
    [self setClientToServerEncrypt:[data sha256PBKDF2KeyWithSalt:@"ClientToServerEnc" iterations:4096 length:32]];
    [self setClientToServerAuth:[data sha256PBKDF2KeyWithSalt:@"ClientToServerAuth" iterations:4096 length:32]];
    [self setServerToClientEncrypt:[data sha256PBKDF2KeyWithSalt:@"ServerToClientEnc" iterations:4096 length:32]];
    [self setServerToClientAuth:[data sha256PBKDF2KeyWithSalt:@"ServerToClientAuth" iterations:4096 length:32]];
    [self setSerializer:[[AGKArgosSerializer alloc] init]];
    [self setDeserializer:[[AGKArgosDeserializer alloc] init]];
    NSData *encrypted = [data plainRsaEncrypt:[self key]];
    uint8_t protocolHeader[2];
    protocolHeader[0] = ([self protocol] >> 8) & 0xFF;
    protocolHeader[1] = [self protocol] & 0xFF;
    [_connection sendData:[NSData dataWithDatas:[NSData dataWithBytesNoCopy:protocolHeader length:2 freeWhenDone:NO], encrypted, nil]];
    for (NSArray *array in [self packetQueue]) {
        [self send:[[array objectAtIndex:0] unsignedIntegerValue] payload:[array objectAtIndex:1]];
    }
    [self setPacketQueue:nil];
}

- (void)connection:(AGKTCPConnection *)connection receivedData:(NSData *)data
{
    NSData *decrypted = [data aesDecryptUsingKey:[self serverToClientEncrypt] sha256SignedUsing:[self serverToClientAuth]];
    if (!decrypted) {
        [[self delegate] connectionLost:AGKArgosConnectionCloseProtocolError];
        [self close];
        return;
    }
    [[self deserializer] setStream:[[AGKDataInputStream alloc] initWithData:decrypted]];
    NSUInteger number = (NSUInteger)[[self deserializer] readUnsignedInteger:4];
    if (number != [self incomingMessageNumber]) {
        [[self delegate] connectionLost:AGKArgosConnectionCloseProtocolError];
        [self close];
        return;
    }
    [self setIncomingMessageNumber:[self incomingMessageNumber] + 1];
    NSUInteger packet = (NSUInteger)[[self deserializer] readUnsignedInteger:2];
    id payload = [[self deserializer] deserialize];
    if (![payload isKindOfClass:[NSDictionary class]])
    {
        [[self delegate] connectionLost:AGKArgosConnectionCloseProtocolError];
        [self close];
        return;
    }
    [[self delegate] receivedPacket:packet payload:payload];
}

- (void)send:(NSUInteger)packet payload:(NSDictionary *)payload
{
    if (![self serializer]) {
        if (![self packetQueue]) [self setPacketQueue:[[NSMutableArray alloc] initWithCapacity:6]];
        [[self packetQueue] addObject:[NSArray arrayWithObjects:N(packet), payload, nil]];
        return;
    }
    [[self serializer] reset];
    [[self serializer] writeInteger:4 value:[self outgoingMessageNumber]];
    [self setOutgoingMessageNumber:[self outgoingMessageNumber] + 1];
    [[self serializer] writeInteger:2 value:packet];
    [[self serializer] add:payload];
    [[self connection] sendData:[[[self serializer] serialize] aesEncryptUsingKey:[self clientToServerEncrypt] sha256SignedUsing:[self clientToServerAuth]]];
}

- (void)connection:(AGKTCPConnection *)connection closed:(AGKTCPConnectionClose)closeReason
{
    if ([self connection] != connection) return;
    [self close];
    switch (closeReason) 
    {
        case AGKTCPConnectionCloseUserClosed:
            break;
        case AGKTCPConnectionCloseConnectionTimeout:
            [[self delegate] connectionLost:AGKArgosConnectionCloseConnectionTimeout];
            break;
        case AGKTCPConnectionCloseStreamClosed:
            [[self delegate] connectionLost:AGKArgosConnectionCloseConnectionClosed];
            break;
        case AGKTCPConnectionCloseStreamError:
            [[self delegate] connectionLost:AGKArgosConnectionCloseConnectionError];
            break;
        default:
            break;
    }
}

- (void)close
{
    [self setOpen:NO];
    [[self connection] setDelegate:nil];
    [[self connection] close];
}

- (void)closeAfterWrite
{
    [self setOpen:NO];
    [[self connection] setDelegate:nil];
    [[self connection] closeAfterWrite];
}

- (void)sendData:(NSData *)data
{
    [[self connection] sendData:data];
}

- (NSString *)hostPortDescription
{
    return NSFORMAT(@"%@:%d", [self host], [self port]);
}

@end
