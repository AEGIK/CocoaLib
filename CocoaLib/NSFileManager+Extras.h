//
//  NSFileManager+Extras.h
//  Voddler
//
//  Created by Christoffer Lernö on 2011-28-03.
//  Copyright 2011 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (Extras)

+ (NSString *)userDirectory:(NSSearchPathDirectory)directory;
+ (NSString *)directory:(NSString *)directory inUserDirectory:(NSSearchPathDirectory)userDirectory;
- (NSError *)setupDirectory:(NSString *)directory;
@end
