//
//  NSURLConnection+Extras.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-10-07.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSURLConnection+Extras.h"
#import "AGK.h"
#import "NSString+Extras.h"
#import "NSString+URLEncode.h"
#import "NSDictionary+Extras.h"
#import "AGKRepeatingEventCentral.h"

static const NSUInteger InitialDataCapacity = 1024;
static const NSTimeInterval DefaultTimeout = 10.0;

@interface NSURLConnectionHandle () {}
@property (nonatomic, weak) _AGKURLConnectionCenter *owner;
@property (nonatomic, weak) NSValue *key;
- (id)initWithConnection:(NSURLConnection *)connection forCenter:(_AGKURLConnectionCenter *)center;
@end

#ifdef DEBUG
static BOOL failAll = NO;
#endif

@implementation NSURLConnection(Extras)

#ifdef DEBUG
+ (void)failAllConnections 
{
    failAll = YES;
}
#endif

+ (NSURLConnectionHandle *)post:(NSString *)urlString 
                         values:(NSDictionary *)postValues 
                     completion:(RequestCompletion)handler {
	return [self post:urlString 
               values:postValues
      requestModifier:NULL
     responseReceived:NULL
           completion:handler
          cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
      timeoutInterval:DefaultTimeout];
	
}

+ (NSURLConnectionHandle *)get:(NSString *)urlString
						values:(NSDictionary *)getValues
					completion:(RequestCompletion)handler {
    
	return [self get:urlString 
			  values:getValues
     requestModifier:NULL
    responseReceived:NULL
		  completion:handler
		 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
	 timeoutInterval:DefaultTimeout];
    
}


+ (NSURLConnectionHandle *)download:(NSString *)urlString 
                             toFile:(NSString *)targetFile 
                         completion:(DownloadCompletion)completion 
{
    return [self download:urlString
                   toFile:targetFile
          requestModifier:NULL
         responseReceived:NULL
               completion:completion];
}

+ (NSURLConnectionHandle *)download:(NSString *)urlString 
                             toFile:(NSString *)targetFile 
                    requestModifier:(RequestModifier)requestModifier
                   responseReceived:(ResponseReceived)responseBlock
                         completion:(DownloadCompletion)completion {
    
#ifdef DEBUG
    if (failAll) {
        if (completion) completion(nil, nil);
        return nil;
    }
#endif
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:urlString]  
                                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                            timeoutInterval:DefaultTimeout];
    
	
    // Modify the request if desired
    if (requestModifier) requestModifier(request);

	
	// Create our delegate to hold data.
    return [[AGKDownloadCenter sharedInstance] download:request toFile:targetFile responseReceived:NULL finished:completion];
}

+ (NSURLConnectionHandle *)post:(NSString *)urlString 
						 values:(NSDictionary *)postValues
                requestModifier:(RequestModifier)requestModifier
               responseReceived:(ResponseReceived)responseBlock
					 completion:(RequestCompletion)handler 
					cachePolicy:(NSURLRequestCachePolicy)cachePolicy 
				timeoutInterval:(NSTimeInterval)timeoutInterval {
	return [self load:urlString
				 post:YES
			   values:postValues
      requestModifier:requestModifier
     responseReceived:responseBlock
           completion:handler
		  cachePolicy:cachePolicy
	  timeoutInterval:timeoutInterval];
	
}

+ (NSURLConnectionHandle *)get:(NSString *)urlString 
						values:(NSDictionary *)getValues
               requestModifier:(RequestModifier)requestModifier
              responseReceived:(ResponseReceived)responseBlock
					completion:(RequestCompletion)handler 
				   cachePolicy:(NSURLRequestCachePolicy)cachePolicy 
			   timeoutInterval:(NSTimeInterval)timeoutInterval {
	
	return [self load:urlString
				 post:NO
			   values:getValues
      requestModifier:requestModifier
     responseReceived:responseBlock
           completion:handler
		  cachePolicy:cachePolicy
	  timeoutInterval:timeoutInterval];
}

+ (NSMutableURLRequest *)requestWithURL:(NSString *)urlString 
                                   post:(BOOL)isPost
                                 values:(NSDictionary *)values 
                            cachePolicy:(NSURLRequestCachePolicy)cachePolicy
                        timeoutInterval:(NSTimeInterval)timeoutInterval
{
    
	// Setup parameters
	NSMutableString *parameter = nil;
	if ([values count]) 
	{
		parameter = [[NSMutableString alloc] initWithCapacity:40];
		for (NSString *key in values) {
			[parameter appendFormat:@"%@=%@&", [key urlEncode], [[NSString stringWithFormat:@"%@", [values objectForKey:key]] urlEncode]];
		}
		[parameter deleteCharactersInRange:NSMakeRange([parameter length] - 1, 1)];		
	}
	
	// If we have a get, append the parameters:
	if (!isPost && parameter) {
		if ([urlString contains:@"?"]) {
			urlString = [urlString stringByAppendingFormat:@"&%@", parameter];
		} else {
			urlString = [urlString stringByAppendingFormat:@"?%@", parameter];
		}
	}
	
	// Create url and request.
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:urlString]  
																cachePolicy:cachePolicy 
															timeoutInterval:timeoutInterval];
	
	if (isPost) {
		[request setHTTPMethod:@"POST"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:[parameter dataUsingEncoding:NSUTF8StringEncoding]];
	} else {
		[request setHTTPMethod:@"GET"];
	}
    return request;	
}

+ (NSURLConnectionHandle *)load:(NSString *)urlString
                           post:(BOOL)isPost
                         values:(NSDictionary *)values
                requestModifier:(RequestModifier)requestModifier 
               responseReceived:(ResponseReceived)responseBlock
                     completion:(RequestCompletion)handler 
                    cachePolicy:(NSURLRequestCachePolicy)cachePolicy 
                timeoutInterval:(NSTimeInterval)timeoutInterval 
{
    
#ifdef DEBUG
    if (failAll) {
        if (handler) handler(nil, nil);
        return nil;
    }
#endif
    
    NSMutableURLRequest *request = [self requestWithURL:urlString
                                                   post:isPost
                                                 values:values
                                            cachePolicy:cachePolicy
                                        timeoutInterval:timeoutInterval];
    if (requestModifier) requestModifier(request);
    
    return [[AGKRemoteLoadCenter sharedInstance] load:request
                                     responseReceived:responseBlock
                                             finished:handler];
}

@end


#pragma mark - Implementation

@interface _AGKBaseData : NSObject {}
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) ResponseReceived responseBlock;
@property (nonatomic, strong) NSString *requestString;
@end

@implementation _AGKBaseData
@synthesize connection = _connection, responseBlock = _responseBlock, requestString = _requestString;
@end

@interface _AGKURLConnectionCenter() {}
@property (nonatomic, strong) NSMutableDictionary *currentConnections;
@property (nonatomic, assign) NSUInteger max;
@property (nonatomic, assign) NSUInteger total;
@property (nonatomic, assign) NSUInteger success;
@property (nonatomic, assign) NSUInteger failed;
@property (nonatomic, assign) NSUInteger cancelled;
@property (nonatomic, assign) BOOL lastResult;
- (void)connectionComplete:(_AGKBaseData *)data;
- (void)connectionFailed:(_AGKBaseData *)data withError:(NSError *)error;
- (void)connection:(_AGKBaseData *)data receivedData:(NSData *)data;
- (void)connectionCancelled:(_AGKBaseData *)data;
- (void)cancel:(NSValue *)key;
- (BOOL)isActive:(NSValue *)key;
- (NSURLConnectionHandle *)schedule:(NSURLConnection *)connection usingData:(id)data responseReceived:(ResponseReceived)responseReceived;
- (void)logStatus;
@end


@implementation _AGKURLConnectionCenter

@synthesize currentConnections = _currentConnections, max = _max, total = _total, cancelled = _cancelled;
@synthesize success = _success, failed = _failed, lastResult = _lastResult;

- (void)logStatus 
{
    // AGKRemoteLoadCenter: 0 connection(s) (max was 3). Total 10/200 ok, 190/200 failed, 0/200 cancelled. Last request OK."
    AGKLog(@"%@: %d connection(s) (max was %d). Total %d/%d ok, %d/%d failed, %d/%d cancelled. Last request %@.",
           [self class], [[self currentConnections] count], [self max], [self success], [self total], [self failed], [self total], [self cancelled], [self total], [self lastResult] ? @"OK" : @"ERROR");
}

- (id)init 
{
    if ((self = [super init])) {
        _currentConnections = [[NSMutableDictionary alloc] initWithCapacity:20];
        _lastResult = YES;
    }
    return self;
}

- (NSURLConnectionHandle *)schedule:(NSURLConnection *)connection usingData:(_AGKBaseData *)data responseReceived:(ResponseReceived)responseReceived
{
    [[self currentConnections] setObject:data forKey:[NSValue valueWithPointer:(__bridge void *)connection]];
    [data setConnection:connection];
    [data setResponseBlock:responseReceived];
    AGKTrace(@"Request \"%@\" sent.", [data requestString]);
    [connection start];
    NSURLConnectionHandle *handle = [[NSURLConnectionHandle alloc] initWithConnection:connection forCenter:self];
    if ([[self currentConnections] count] > [self max]) {
        [self setMax:[[self currentConnections] count]];
    }
    _total++;
    return handle;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [[protectionSpace authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if ([[[challenge protectionSpace] authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		[[challenge sender] useCredential:[NSURLCredential credentialForTrust:[[challenge protectionSpace] serverTrust]] forAuthenticationChallenge:challenge];
		return;
	}
	[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    NSValue *pointer = [NSValue valueWithPointer:(__bridge void *)aConnection];
    id data = [[self currentConnections] objectForKey:pointer];
    [[self currentConnections] removeObjectForKey:pointer];
    if (!data) return;
    AGKTrace(@"Request \"%@\" completed.", [data requestString]);
    [self connectionComplete:data];
    _success++;
    [self setLastResult:YES];
}

- (void)connectionComplete:(_AGKBaseData *)baseData 
{}

- (void)connectionCancelled:(_AGKBaseData *)data 
{}

- (void)connectionFailed:(_AGKBaseData *)data withError:(NSError *)error 
{}

- (void)connection:(_AGKBaseData *)data receivedData:(NSData *)theData 
{}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error 
{
    NSValue *pointer = [NSValue valueWithPointer:(__bridge void *)aConnection];
    id data = [[self currentConnections] objectForKey:pointer];
    [[self currentConnections] removeObjectForKey:pointer];
    if (!data) return;
    AGKTrace(@"Request \"%@\" failed.", [data requestString]);
    [self connectionFailed:data withError:error];
    _failed++;
    [self setLastResult:NO];
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)theData 
{
    id data = [[self currentConnections] objectForKey:[NSValue valueWithPointer:(__bridge void *)aConnection]];
    if (data) [self connection:data receivedData:theData];
}

- (BOOL)isActive:(NSValue *)key 
{
	return [[self currentConnections] objectForKey:key] != nil;
}

- (void)cancel:(NSValue *)key 
{
    id data = [[self currentConnections] objectForKey:key];
    if (data) {
        [[data connection] cancel];
        [[self currentConnections] removeObjectForKey:key];
        AGKTrace(@"Request \"%@\" cancelled.", [data requestString]);
        [self connectionCancelled:data];
        _cancelled++;
        [self setLastResult:NO];
    }
}

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response 
{
    id data = [[self currentConnections] objectForKey:[NSValue valueWithPointer:(__bridge void *)aConnection]];
    if ([data responseBlock]) {
        [data responseBlock](response);
    }
}

@end

#pragma mark - AGKRemoteLoadCenter

@interface AGKRemoteLoadCenter() {}
@end

@interface AGKRemoteLoadData : _AGKBaseData {}
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) RequestCompletion block;
@end

@implementation AGKRemoteLoadCenter

+ (AGKRemoteLoadCenter *)sharedInstance 
{
    static AGKRemoteLoadCenter *instance = nil;
    if (!instance) {
        instance = [[AGKRemoteLoadCenter alloc] init];
        [[AGKRepeatingEventCentral sharedInstance] addObserver:instance selector:@selector(logStatus) forEvent:AGKRepeatingEvent30s];
    }
    return instance;
}

- (NSURLConnectionHandle *)load:(NSURLRequest *)request responseReceived:(ResponseReceived)responseReceived finished:(RequestCompletion)block
{

    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    
    if (!connection) {
        block(nil, nil);
        return nil;
    }
    
    AGKRemoteLoadData *data = [[AGKRemoteLoadData alloc] init];
    [data setBlock:block];
    [data setRequestString:[[request URL] absoluteString]];
    NSURLConnectionHandle *handle = [self schedule:connection usingData:data responseReceived:responseReceived];
    return handle;
}

- (void)connectionFailed:(AGKRemoteLoadData *)data withError:(NSError *)error 
{
    if (![data block]) return;
    [data block](nil, error);
}

- (void)connectionComplete:(AGKRemoteLoadData *)data {
    if (![data block]) return;
    [data block]([data data], nil);
}

- (void)connection:(AGKRemoteLoadData *)data receivedData:(NSData *)theData 
{
    if (![data data]) {
        [data setData:theData];
        return;
    }
    NSData *currentData = [data data];
    if ([currentData isKindOfClass:[NSMutableData class]]) {
        [(NSMutableData *)currentData appendData:theData];
    } else {
        NSMutableData *newData = [[NSMutableData alloc] initWithCapacity:[currentData length] + [theData length] * 2];
        [newData appendData:currentData];
        [newData appendData:theData];
        [data setData:newData];
    }
}

@end

@implementation AGKRemoteLoadData
@synthesize data, block;
@end

#pragma mark - AGKDownloadCenter

@interface AGKDownloadCenter() {}
@property (nonatomic, strong) NSFileManager *fileManager;
@end

@interface AGKDownloadData : _AGKBaseData {}
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) DownloadCompletion block;
@property (nonatomic, strong) NSString *fileName;
@end

@implementation AGKDownloadCenter

@synthesize fileManager = _fileManager;

+ (AGKDownloadCenter *)sharedInstance
{
    static AGKDownloadCenter *instance = nil;
    if (!instance) {
        instance = [[AGKDownloadCenter alloc] init];
        [[AGKRepeatingEventCentral sharedInstance] addObserver:instance selector:@selector(logStatus) forEvent:AGKRepeatingEvent30s];
    }
    return instance;
}

- (id)init 
{
    if ((self = [super init])) {
        _fileManager = [[NSFileManager alloc] init];
    }
    return self;
}

- (NSURLConnectionHandle *)download:(NSURLRequest *)request toFile:(NSString *)filePath responseReceived:(ResponseReceived)responseReceived finished:(DownloadCompletion)block
{
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    
    if (!connection) {
        block(nil, nil);
        return nil;
    }
    
    NSData *nilData = [[NSData alloc] initWithBytes:NULL length:0];
    NSError *error = nil;
    [[self fileManager] removeItemAtPath:filePath error:&error];
    BOOL createdOk = [[self fileManager] createFileAtPath:filePath contents:nilData attributes:nil];
    
    if (!createdOk) {
        AGKLog(@"Failed to create file %@ for download: %@", filePath, error);
        block(nil, nil);
        return nil;
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        AGKLog(@"Failed to create file handle %@ for download.", filePath);
        block(nil, nil);
        return nil;
    }
    
    AGKDownloadData *data = [[AGKDownloadData alloc] init];
    [data setBlock:block];
    [data setFileHandle:fileHandle];
    [data setFileName:filePath];
    [data setRequestString:[[request URL] absoluteString]];
    return [self schedule:connection usingData:data responseReceived:responseReceived];
}

- (void)connection:(AGKDownloadData *)data receivedData:(NSData *)theData 
{
    [[data fileHandle] writeData:theData];
}

- (void)connectionComplete:(AGKDownloadData *)data {
    [[data fileHandle] closeFile];
    DownloadCompletion block = [data block];
    if (block) block([data fileName], nil);
}

- (void)deleteFile:(AGKDownloadData *)data {
    [[data fileHandle] closeFile];
    [[self fileManager] removeItemAtPath:[data fileName] error:NULL];			
}

- (void)connectionFailed:(AGKDownloadData *)data withError:(NSError *)error 
{
    [self deleteFile:data];
    DownloadCompletion block = [data block];
    if (block) block(nil, error);
}

- (void)connectionCancelled:(AGKDownloadData *)data 
{
    [self deleteFile:data];
}

@end

@implementation AGKDownloadData 
@synthesize fileHandle, block, fileName;
@end

@implementation NSURLConnectionHandle
@synthesize key = _key, owner = _owner;

- (id)initWithConnection:(NSURLConnection *)connection forCenter:(AGKRemoteLoadCenter *)center 
{
    if ((self = [super init])) {
        _key = [NSValue valueWithPointer:(__bridge void *)connection];
        _owner = center;
    }
    return self;
}

- (BOOL)isActive
{
    return [[self owner] isActive:[self key]];
}

- (void)cancel
{
    [[self owner] cancel:[self key]];
}


@end

