//
//  NSURLConnection+Extras.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-10-07.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RequestCompletion)(NSData *data, NSError *error);
typedef void (^DownloadCompletion)(NSString *path, NSError *error);
typedef void (^ResponseReceived)(NSURLResponse *response);
typedef void (^RequestModifier)(NSMutableURLRequest *request);
@interface NSURLConnectionHandle : NSObject {}
- (BOOL)isActive;
- (void)cancel;
@end

@interface NSURLConnection(Extras) 

#ifdef DEBUG
+ (void)failAllConnections;
#endif

+ (NSMutableURLRequest *)requestWithURL:(NSString *)urlString 
                                   post:(BOOL)isPost
                                 values:(NSDictionary *)values 
                            cachePolicy:(NSURLRequestCachePolicy)cachePolicy
                        timeoutInterval:(NSTimeInterval)timeoutInterval;

+ (NSURLConnectionHandle *)post:(NSString *)urlString 
                         values:(NSDictionary *)postValues 
                     completion:(RequestCompletion)handler;

+ (NSURLConnectionHandle *)post:(NSString *)urlString 
                         values:(NSDictionary *)postValues
                requestModifier:(RequestModifier)requestModifier
               responseReceived:(ResponseReceived)responseBlock
                     completion:(RequestCompletion)handler 
                    cachePolicy:(NSURLRequestCachePolicy)cachePolicy 
                timeoutInterval:(NSTimeInterval)timeoutInterval;

+ (NSURLConnectionHandle *)get:(NSString *)urlString
                        values:(NSDictionary *)getValues
                    completion:(RequestCompletion)handler;

+ (NSURLConnectionHandle *)get:(NSString *)urlString 
                        values:(NSDictionary *)getValues
               requestModifier:(RequestModifier)requestModifier
              responseReceived:(ResponseReceived)responseBlock
                    completion:(RequestCompletion)handler 
                   cachePolicy:(NSURLRequestCachePolicy)cachePolicy 
               timeoutInterval:(NSTimeInterval)timeoutInterval;

+ (NSURLConnectionHandle *)load:(NSString *)url
                           post:(BOOL)usePost
                         values:(NSDictionary *)keyValues
                requestModifier:(RequestModifier)requestModifier
               responseReceived:(ResponseReceived)responseBlock
                     completion:(RequestCompletion)completionBlock
                    cachePolicy:(NSURLRequestCachePolicy)cachePolicy 
                timeoutInterval:(NSTimeInterval)timeoutInterval;

+ (NSURLConnectionHandle *)download:(NSString *)urlString 
                             toFile:(NSString *)targetFile 
                    requestModifier:(RequestModifier)requestModifier
                   responseReceived:(ResponseReceived)responseBlock
                         completion:(DownloadCompletion)handler;

+ (NSURLConnectionHandle *)download:(NSString *)urlString 
                             toFile:(NSString *)targetFile 
                         completion:(DownloadCompletion)handler;

@end

@interface _AGKURLConnectionCenter : NSObject {}
@end

@interface AGKDownloadCenter : _AGKURLConnectionCenter {}
+ (AGKDownloadCenter *)sharedInstance;
- (NSURLConnectionHandle *)download:(NSURLRequest *)request toFile:(NSString *)filePath responseReceived:(ResponseReceived)responseReceived finished:(DownloadCompletion)block;
@end

@interface AGKRemoteLoadCenter : _AGKURLConnectionCenter {}
+ (AGKRemoteLoadCenter *)sharedInstance;
- (NSURLConnectionHandle *)load:(NSURLRequest *)request responseReceived:(ResponseReceived)responseReceived finished:(RequestCompletion)block;

@end
