//
//  AGKRepeatingEventCentral.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2011-12-04.
//  Copyright 2011 Aegik AB. All rights reserved.
//

#import "AGKRepeatingEventCentral.h"
#import "AGK.h"
@interface AGKRepeatingEntry : NSObject {}
@property (nonatomic, weak) id observer;
@property (nonatomic, assign) SEL selector;
@end

@implementation AGKRepeatingEntry
@synthesize observer, selector;
@end

__strong AGKRepeatingEventCentral *sharedInstance = nil;

@interface AGKRepeatingEventCentral() {}
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) unsigned long long counter;
@property (nonatomic, strong) NSArray *observers;
@end

@implementation AGKRepeatingEventCentral

@synthesize timer = _timer, counter = _counter, observers = _observers;

+ (AGKRepeatingEventCentral *)sharedInstance 
{
    if (!sharedInstance) {
        sharedInstance = [[AGKRepeatingEventCentral alloc] init];
    }
    return sharedInstance;
}

- (void)addObserver:(id)observer selector:(SEL)selector forEvent:(AGKRepeatingEvent)event
{
    NSMutableArray *entry = [[self observers] objectAtIndex:event];
    AGKRepeatingEntry *observerEntry = [[AGKRepeatingEntry alloc] init];
    [observerEntry setObserver:observer];
    [observerEntry setSelector:selector];
    [entry addObject:observerEntry];
}

- (void)removeObserver:(id)observer 
{
    for (NSMutableArray *array in [self observers]) {
        if (![array count]) continue;
        for (AGKRepeatingEntry *entry in [NSArray arrayWithArray:array]) {
            if ([entry observer] == observer || ![entry observer]) {
                [array removeObject:entry];
            }
        }
    }
}

- (void)notifyObserversForEvent:(AGKRepeatingEvent)event 
{
    NSArray *array = [[self observers] objectAtIndex:event];
    if (![array count]) return;
    NSArray *copy = [[NSArray alloc] initWithArray:array];
    for (AGKRepeatingEntry *entry in copy) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [[entry observer] performSelector:[entry selector] withObject:nil];
#pragma clang diagnostic pop

    }
}

- (void)timerFired:(NSTimer *)timer {
    unsigned long long currentCounter = [self counter];
    [self setCounter:currentCounter + 1];
    [self notifyObserversForEvent:AGKRepeatingEvent500ms];
    if (currentCounter % 2 != 0) return;
    // To seconds
    currentCounter /= 2;
    [self notifyObserversForEvent:AGKRepeatingEvent1s];
    if (currentCounter % 5 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent5s];
    }

    if (currentCounter % 10 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent10s];
    }

    if (currentCounter % 15 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent15s];
    }

    if (currentCounter % 30 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent30s];
    }

    if (currentCounter % 60 != 0) return;
    
    // To minutes
    currentCounter /= 60;
    [self notifyObserversForEvent:AGKRepeatingEvent1min];
    
    if (currentCounter % 2 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent2min];
    }
    
    if (currentCounter % 5 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent5min];
    }
    
    if (currentCounter % 10 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent10min];
    }
    
    if (currentCounter % 15 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent15min];
    }
    
    if (currentCounter % 30 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent30min];
    }
    
    if (currentCounter % 60 != 0) return;
    
    // To hours
    currentCounter /= 60;
    [self notifyObserversForEvent:AGKRepeatingEvent1h];
    
    if (currentCounter % 2 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent2h];
    }
    
    if (currentCounter % 6 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent6h];
    }
    
    if (currentCounter % 12 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEvent12h];
    }
    
    if (currentCounter % 24 == 0) {
        [self notifyObserversForEvent:AGKRepeatingEventDaily];
    }
}

- (id)init 
{
    if ((self = [super init])) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:AGKRepeatingEventSentinel];
        for (int i = 0; i < AGKRepeatingEventSentinel; i++) {
            [array addObject:[NSMutableArray array]];
        }
        _observers = [[NSArray alloc] initWithArray:array];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5 
                                                  target:self 
                                               selector:@selector(timerFired:) 
                                               userInfo:nil 
                                                repeats:YES];
    }
    return self;
}
@end
