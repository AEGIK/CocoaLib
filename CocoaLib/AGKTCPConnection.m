//
//  AGKTCPConnection.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-24-06.
//  Copyright 2011 AEGIK AB. All rights reserved.
//

#import "AGKTCPConnection.h"
#import "NSData+Extras.h"
#import "AGK.h"
#import <CFNetwork/CFNetwork.h>

@interface _AGKTCPConnectionIO : NSObject<NSStreamDelegate> {}

- (id)initWithStream:(NSStream *)stream parent:(AGKTCPConnection *)parent;
- (void)close;

@property (nonatomic, strong) NSStream *stream;
@property (nonatomic, weak) AGKTCPConnection *parent;
@property (nonatomic, weak) NSRunLoop *runLoop;
@property (nonatomic, assign, getter = isConnected) BOOL connected;

@end

@interface _AGKTCPConnectionIn : _AGKTCPConnectionIO {}
@end

@interface _AGKTCPConnectionOut : _AGKTCPConnectionIO {}

- (void)addData:(NSData *)data;
@property (nonatomic, strong) NSMutableArray *outgoingPackets;
@property (nonatomic, assign) NSUInteger offset;

@end


@interface AGKTCPConnection() {}

+ (void)runNetworkThread;
+ (NSThread *)networkThread;
- (void)runOnNetworkThreadSelector:(SEL)selector object:(id)object;
- (void)runOnMainThreadSelector:(SEL)selector object:(id)object;
- (void)closeOnNetworkThread:(AGKTCPConnectionClose)closeReason;
@property (nonatomic, strong) _AGKTCPConnectionIn *input;
@property (nonatomic, strong) _AGKTCPConnectionOut *output;
@property (nonatomic, assign, readwrite, getter = isOpen) BOOL open;
@property (nonatomic, assign, readwrite, getter = isConnected) BOOL connected;
@end

@implementation AGKTCPConnection
@synthesize host = _host, port = _port, input = _input, output = _output, open = _open, delegate = _delegate;
@synthesize connected = _connected, reader = _reader, writer = _writer;

+ (void)runNetworkThread
{
    @autoreleasepool {
        NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];
        NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate distantFuture] interval:10000 target:nil selector:@selector(fire) userInfo:nil repeats:YES];
        [myRunLoop addTimer:timer forMode:NSDefaultRunLoopMode];
        [myRunLoop run];
    }
}

+ (NSThread *)networkThread
{
    static __strong NSThread *thread = nil;
    if (!thread) {
        thread = [[NSThread alloc] initWithTarget:self selector:@selector(runNetworkThread) object:nil];
        [thread start];
    }
    return thread;
}

- (id)initWithHost:(NSString *)host port:(NSUInteger)port
{
    if ((self = [super init])) {
        _host = [host copy];
        _port = port;
    }
    return self;
}

#pragma mark - Threading helpers

- (void)runOnMainThreadSelector:(SEL)selector object:(id)object
{
    [self performSelector:selector onThread:[NSThread mainThread] withObject:object waitUntilDone:NO];
}

- (void)runOnNetworkThreadSelector:(SEL)selector object:(id)object
{
    [self performSelector:selector onThread:[AGKTCPConnection networkThread] withObject:object waitUntilDone:NO];
}

#pragma mark - Data sending

- (void)sendDataNetworkThread:(NSData *)data
{
    [[self output] addData:data];
}

- (void)sendData:(NSData *)data
{
    if (data && [self writer]) {
        NSData *prepend = [[self writer] prependData:data];
        if (prepend) [self runOnNetworkThreadSelector:@selector(sendDataNetworkThread:) object:prepend];
        NSData *transformedData = [[self writer] transformData:data];
        if (transformedData) [self runOnNetworkThreadSelector:@selector(sendDataNetworkThread:) object:transformedData];
        NSData *append = [[self writer] appendData:data];
        if (append) [self runOnNetworkThreadSelector:@selector(sendDataNetworkThread:) object:append];
    } else {
        [self runOnNetworkThreadSelector:@selector(sendDataNetworkThread:) object:data];
    }
}

#pragma mark - Data reading

- (void)readBytes:(NSData *)data
{
    if ([[self delegate] respondsToSelector:@selector(connection:receivedData:)]) {
        if ([self reader]) {
            data = [[self reader] assemblePacket:data];
        }
        if (data) [[self delegate] connection:self receivedData:data];
    }    
}
     
- (void)readBytesOnNetworkThread:(NSData *)data
{
    [self runOnMainThreadSelector:@selector(readBytes:) object:data];
}

- (void)loginTimeoutOnNetworkThread
{
    if ([self input] && ![[self input] isConnected]) {
        [self closeOnNetworkThread:AGKTCPConnectionCloseConnectionTimeout];
    }
}
- (void)openOnNetworkThread
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)[self host], [self port], &readStream, &writeStream);
    [self setInput:[[_AGKTCPConnectionIn alloc] initWithStream:(__bridge_transfer NSStream *)readStream parent:self]];
    [self setOutput:[[_AGKTCPConnectionOut alloc] initWithStream:(__bridge_transfer NSStream *)writeStream parent:self]];
    [self performSelector:@selector(loginTimeoutOnNetworkThread) withObject:nil afterDelay:10];
}

- (void)open
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if ([self isOpen]) return;
    [self setOpen:YES];
    [self setConnected:NO];
    [self runOnNetworkThreadSelector:@selector(openOnNetworkThread) object:nil];
}

- (void)streamClosed
{
    if (![self isOpen]) return;
    if ([[self delegate] respondsToSelector:@selector(connection:closed:)]) {
        [[self delegate] connection:self closed:AGKTCPConnectionCloseStreamClosed];
    }
    [self setOpen:NO];
}

- (void)closeOnNetworkThread:(AGKTCPConnectionClose)closeReason
{
    [[self input] close];
    [[self output] close];
    [self setInput:nil];
    [self setOutput:nil];
    [self runOnMainThreadSelector:@selector(streamClosed) object:nil];
}

- (void)closeRequestNetworkThread
{
    [self closeOnNetworkThread:AGKTCPConnectionCloseUserClosed];
}

- (void)closeAfterWrite
{
    [self sendData:nil];
}

- (BOOL)isCurrentStream:(_AGKTCPConnectionIO *)stream
{
    return ([self input] == stream || [self output] == stream);
}

- (void)streamOpened
{
    if ([self isConnected]) return;
    [self setConnected:YES];
    if ([[self delegate] respondsToSelector:@selector(connectionOpened:)]) {
        [[self delegate] connectionOpened:self];
    }
}

- (void)streamOpenedOnNetworkThread:(_AGKTCPConnectionIO *)stream
{
    if ([self isCurrentStream:stream]) {
        [self runOnMainThreadSelector:@selector(streamOpened) object:nil];
    }
}
- (void)streamClosedOnNetworkThread:(_AGKTCPConnectionIO *)stream
{
    if ([self isCurrentStream:stream]) [self closeOnNetworkThread:AGKTCPConnectionCloseStreamClosed];
}

- (void)streamErrorOnNetworkThread:(_AGKTCPConnectionIO *)stream
{
    if ([self isCurrentStream:stream]) [self closeOnNetworkThread:AGKTCPConnectionCloseStreamError];
}

- (void)close
{
    if (![self isOpen]) return;
    [self setOpen:NO];
    [self runOnNetworkThreadSelector:@selector(closeRequestNetworkThread) object:nil];
}

- (NSString *)hostPortDescription
{
    return NSFORMAT(@"%@:%d", [self host], [self port]);
}
@end

@implementation _AGKTCPConnectionIO

@synthesize stream = _stream, parent = _parent, runLoop = _runLoop, connected = _connected;

- (id)initWithStream:(NSStream *)stream parent:(AGKTCPConnection *)parent
{
    if ((self = [super init])) {
        _stream = stream;
        _connected = NO;
        _runLoop = [NSRunLoop currentRunLoop];
        _parent = parent;
        [stream setDelegate:self];
        [stream scheduleInRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
        [stream open];            
    }
    return self;
}

- (void)close
{
    [[self stream] close];
    [[self stream] removeFromRunLoop:[self runLoop]
                             forMode:NSDefaultRunLoopMode];
    [self setStream:nil];    
}

- (void)closeOnStreamEnd
{
    [self close];
    [[self parent] streamClosedOnNetworkThread:self];    
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            [self setConnected:YES];
            [[self parent] streamOpenedOnNetworkThread:self];
            break;
        case NSStreamEventErrorOccurred:
            [self close];
            [[self parent] streamErrorOnNetworkThread:self];
            break;
        case NSStreamEventEndEncountered:
            [self closeOnStreamEnd];
            break;
    }
}

- (void)dealloc
{
    [_stream close];
    if (_runLoop) [_stream removeFromRunLoop:_runLoop forMode:NSDefaultRunLoopMode];
}

@end
    
@implementation _AGKTCPConnectionOut

@synthesize outgoingPackets = _outgoingPackets, offset = _offset;

- (id)initWithStream:(NSStream *)stream parent:(AGKTCPConnection *)parent
{
    if ((self = [super initWithStream:stream parent:parent])) {
        _outgoingPackets = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}

- (void)close
{
    [super close];
    [self setOutgoingPackets:nil];
}

- (void)writeData
{
    if (![[self outgoingPackets] count] || ![(NSOutputStream *)[self stream] hasSpaceAvailable]) return;
    
    id currentData = [[self outgoingPackets] objectAtIndex:0];
    if (currentData == [NSNull null]) {
        [self closeOnStreamEnd];
        [self setOutgoingPackets:nil];
        return;
    }
    const void *pointer = [currentData bytes] + [self offset];
    NSInteger sent = [(NSOutputStream *)[self stream] write:pointer maxLength:[currentData length] - [self offset]];
    if (sent < 0) {
        [self closeOnStreamEnd];
        [self setOutgoingPackets:nil];
        return;
    }
    NSUInteger newOffset = (NSUInteger)sent + [self offset];
    if (newOffset == [currentData length]) {
        [self setOffset:0];
        [[self outgoingPackets] removeObjectAtIndex:0];
        [self performSelector:@selector(writeData) withObject:nil afterDelay:0.0];
    } else {
        [self setOffset:newOffset];
    }
}

- (void)addData:(NSData *)data
{
    if (![self outgoingPackets]) return;
    if (data == nil) {
        [[self outgoingPackets] addObject:[NSNull null]];
    } else {
        [[self outgoingPackets] addObject:data];
    }
    [self writeData];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasSpaceAvailable:
            [self writeData];
            break;
        default:
            [super stream:aStream handleEvent:eventCode];
            break;
    }
}
@end

@implementation _AGKTCPConnectionIn

- (id)initWithStream:(NSStream *)stream parent:(AGKTCPConnection *)parent
{
    if ((self = [super initWithStream:stream parent:parent])) {
        
    }
    return self;
}

- (void)readBytes
{
    static uint8_t *buffer = NULL;
    static NSUInteger bufferSize = 16 * 1024;
    if (!buffer) buffer = calloc(bufferSize, sizeof(uint8_t));
    
    NSInteger read;
    while ((read = [(NSInputStream *)[self stream] read:buffer maxLength:bufferSize])) {
        if (read < 0) {
            [self closeOnStreamEnd];
            return;
        }
        NSData *data = [[NSData alloc] initWithBytes:buffer length:(NSUInteger)read];
        [[self parent] readBytesOnNetworkThread:data];
        if (![(NSInputStream *)[self stream] hasBytesAvailable]) return;
    }
}
           
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:
            [self readBytes];
            break;
        default:
            [super stream:aStream handleEvent:eventCode];
            break;
    }
}

@end

@interface AGKTCPConnectionStandardReader() {}
@property (nonatomic, assign) NSUInteger headerSize;
@property (nonatomic, assign) NSUInteger length;
@property (nonatomic, strong) NSMutableData *payload;
@end

@implementation AGKTCPConnectionStandardReader
@synthesize headerSize = _headerSize, payload = _payload, length = _length;

- (id)initWithHeaderSize:(NSUInteger)headerSize
{
    if ((self = [super init])) {
        _headerSize = headerSize;
        _payload = [[NSMutableData alloc] initWithCapacity:10];
    }
    return self;
}

- (void)reset
{
    [[self payload] setLength:0];
    [self setLength:0];
}

- (void)calculateLength
{
    if ([[self payload] length] < [self headerSize]) return;
    uint8_t *bytes = (uint8_t *)[[self payload] mutableBytes];
    NSUInteger length = 0;
    for (NSUInteger i = 0; i < [self headerSize]; i++) {
        length <<= 8;
        length |= bytes[i];
    }
    [self setLength:length];
}

- (NSData *)assemblePacket:(NSData *)data
{
    if (![self length]) {
        [[self payload] appendData:data];
        [self calculateLength];
        if (![self length]) return nil;
    }
    NSUInteger end = [self headerSize] + [self length];
    if ([[self payload] length] < end) return nil;
    NSData *packet = [[self payload] subdataWithRange:NSMakeRange([self headerSize], [self length])];
    if (end == [[self payload] length]) {
        [[self payload] setLength:0];
    } else {
        NSData *tailData = [[self payload] subdataWithRange:NSMakeRange(end, [[self payload] length] - end)];
        [[self payload] setData:tailData];
    }
    [self setLength:0];
    return packet;
}
@end

@interface AGKTCPConnectionStandardWriter() {}
@property (nonatomic, assign) NSUInteger headerSize;
@end

@implementation AGKTCPConnectionStandardWriter

@synthesize headerSize = _headerSize;

- (id)initWithHeaderSize:(NSUInteger)headerSize
{
    if ((self = [super init])) {
        _headerSize = headerSize;
    }
    return self;
}

- (NSData *)appendData:(NSData *)data
{
    return nil;
}

- (NSData *)prependData:(NSData *)data
{
    NSMutableData *prepend = [[NSMutableData alloc] initWithCapacity:[self headerSize]];
    NSUInteger length = [data length];
    for (int i = (NSInteger)[self headerSize] * 8 - 8; i >= 0; i -= 8) {
        [prepend writeByte:(length >> i) & 0xFF];
    }
    return prepend;
}

- (NSData *)transformData:(NSData *)data
{
    return data;
}

@end
