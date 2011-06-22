//
//  NSObject+KVO.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-13-09.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject(KVO)
- (void)addObserver:(id)observer performSelector:(SEL)selector forKeyPath:(NSString *)keypath options:(NSKeyValueObservingOptions)options;
- (void)bind:(NSString *)keypath toObserver:(id)observer usingSelector:(SEL)selector;
- (void)stopObservingAll;
- (void)stopObserving:(id)object;
@end
