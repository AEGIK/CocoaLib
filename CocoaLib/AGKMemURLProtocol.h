//
//  AGKMemURLProtocol.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-04-05.
//  Copyright 2011 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface AGKMemURLProtocol : NSURLProtocol {
    
}

+ (void)registerMemFile:(NSString *)path data:(NSData *)data;
+ (void)unregisterMemFile:(NSString *)path;

@end
