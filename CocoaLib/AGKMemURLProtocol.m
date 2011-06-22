//
//  AGKMemURLProtocol.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-04-05.
//  Copyright 2011 Aegik AB. All rights reserved.
//

#import "AGKMemURLProtocol.h"

static NSMutableDictionary *storedData();

static NSMutableDictionary *storedData() 
{
    static NSMutableDictionary *data = nil;
    if (!data) {
        data = [[NSMutableDictionary alloc] init];
    }
    return data;
}

@implementation AGKMemURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request 
{
    return [[[request URL] scheme] caseInsensitiveCompare:@"mem"] == NSOrderedSame;
}

+ (void)registerMemURL {
    static BOOL inited = NO;
	if (!inited) {
		[NSURLProtocol registerClass:[AGKMemURLProtocol class]];
		inited = YES;
	}
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request 
{
    return request;
}

+ (void)registerMemFile:(NSString *)path data:(NSData *)data
{
    [self registerMemURL];
    [storedData() setObject:data forKey:path];
}

+ (void)unregisterMemFile:(NSString *)path 
{
    [storedData() removeObjectForKey:path];
}

- (void)startLoading 
{
    NSString *path = [[[[self request] URL] absoluteString] substringFromIndex:6];
    NSData *data = [storedData() objectForKey:path];
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[[self request] URL]
                                                        MIMEType:@"binary/octet-stream"
                                           expectedContentLength:(NSInteger)[data length]
                                                textEncodingName:nil];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [[self client] URLProtocol:self didLoadData:data];
    [[self client] URLProtocolDidFinishLoading:self];
    if (!data) {
        [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:1 userInfo:nil]];
        return;
    }
}

- (void)stopLoading 
{
    
}
@end
