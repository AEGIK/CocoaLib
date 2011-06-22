//
//  AGKRepeatingEventCentral.h
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-12-04.
//  Copyright 2011 Aegik AB. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _AGKRepeatingEvent {
    AGKRepeatingEventDaily = 0,
    AGKRepeatingEvent12h,
    AGKRepeatingEvent6h,
    AGKRepeatingEvent2h,
    AGKRepeatingEvent1h,
    AGKRepeatingEvent30min,
    AGKRepeatingEvent15min,
    AGKRepeatingEvent10min,
    AGKRepeatingEvent5min,
    AGKRepeatingEvent2min,
    AGKRepeatingEvent1min,
    AGKRepeatingEvent30s,
    AGKRepeatingEvent15s,
    AGKRepeatingEvent10s,
    AGKRepeatingEvent5s,
    AGKRepeatingEvent1s,
    AGKRepeatingEvent500ms,
    AGKRepeatingEventSentinel
} AGKRepeatingEvent;

@interface AGKRepeatingEventCentral : NSObject {
}

+ (AGKRepeatingEventCentral *)sharedInstance;
- (void)removeObserver:(id)observer;
- (void)addObserver:(id)observer selector:(SEL)selector forEvent:(AGKRepeatingEvent)event;
@end
