//
//  NSObject+KVO.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-13-09.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSObject+KVO.h"

@interface AGKObservation : NSObject
@property (weak, nonatomic) id observer;
@property (strong, nonatomic) id observed;
@property (strong, nonatomic) NSString *keyPath;
@property (assign, nonatomic) BOOL sendValue;
- (void)cancel;
@end

@interface AGKObservationCenter : NSObject {}
+ (AGKObservationCenter*)sharedInstance;
- (void)removeObserver:self;
- (void)removeObserver:(id)observer forObject:(id)observed;
- (void)registerObserver:(id)observer forObject:(id)object selector:(SEL)selector forKeyPath:(NSString *)keypath options:(NSKeyValueObservingOptions)options sendValue:(BOOL)sendValue;
@property (nonatomic, strong) NSMutableDictionary *observers;

@end

@implementation NSObject(KVO)

- (void)bind:(NSString *)keypath toObserver:(id)observer usingSelector:(SEL)selector {
	[[AGKObservationCenter sharedInstance] registerObserver:observer forObject:self selector:selector forKeyPath:keypath options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew sendValue:YES];	
}
- (void)addObserver:(id)observer performSelector:(SEL)selector forKeyPath:(NSString *)keypath options:(NSKeyValueObservingOptions)options {
	[[AGKObservationCenter sharedInstance] registerObserver:observer forObject:self selector:selector forKeyPath:keypath options:options sendValue:NO];
}

- (void)stopObserving:(id)object {
	[[AGKObservationCenter sharedInstance] removeObserver:self forObject:object];
}

- (void)stopObservingAll {
	[[AGKObservationCenter sharedInstance] removeObserver:self];
}

@end

@implementation AGKObservation

@synthesize observer, observed, keyPath, sendValue;

- (void)cancel {
	
	[self setObserver:nil];
	[[self observed] removeObserver:self forKeyPath:[self keyPath]];
	[self setObserved:nil];
	[self setKeyPath:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context 
{
	id payload = [self sendValue] ? [change objectForKey:NSKeyValueChangeNewKey] : change;
	if (payload == [NSNull null]) payload = nil;
	[[self observer] performSelector:(SEL)context withObject:payload];
}

- (void)dealloc 
{
	[self cancel];
}

@end
static AGKObservationCenter *sharedInstance = nil;

@implementation AGKObservationCenter

@synthesize observers;

#pragma mark -
#pragma mark class instance methods

- (id)init {
	if ((self = [super init])) {
		[self setObservers:[NSMutableDictionary dictionaryWithCapacity:10]];
	}
	return self;
}

- (void)registerObserver:(id)observer forObject:(id)object selector:(SEL)selector forKeyPath:(NSString *)keypath options:(NSKeyValueObservingOptions)options sendValue:(BOOL)sendValue 
{
	if (![observer respondsToSelector:selector]) [NSException raise:NSGenericException format:@"%@ does not respond to selector %@", observer, NSStringFromSelector(selector)];
	AGKObservation *observation;
	@synchronized(self) {
		observation = [[AGKObservation alloc] init];
		[observation setObserved:object];
		[observation setObserver:observer];
		[observation setKeyPath:keypath];
		[observation setSendValue:sendValue];
		NSValue *key = [NSValue valueWithPointer:(__bridge void *)observer];
		NSMutableArray *otherObservers = [[self observers] objectForKey:key];
		if (!otherObservers) {
			otherObservers = [[NSMutableArray alloc] initWithCapacity:2];
			[[self observers] setObject:otherObservers forKey:key];
		}
		[otherObservers addObject:observation];
	}
	[object addObserver:observation forKeyPath:keypath options:options context:selector];
}

- (void)removeObserver:(id)observer forObject:(id)observed 
{
	if (observed == nil) return;
	@synchronized(self) {
		NSValue *key = [NSValue valueWithPointer:(__bridge void *)observer];
		NSMutableArray *currentObservers = [[self observers] objectForKey:key];
		if (!currentObservers) return;
		for (AGKObservation *observation in [NSArray arrayWithArray:currentObservers]) {
			if ([observation observed] == observed) {
				[observation cancel];				
				[currentObservers removeObject:observation];
			}
		}
		if ([currentObservers count] == 0) {
			[[self observers] removeObjectForKey:key];			
		}
	}
	
}
- (void)removeObserver:(id)observer {
	@synchronized(self) {
		NSValue *key = [NSValue valueWithPointer:(__bridge void *)observer];
		for (AGKObservation *observation in [[self observers] objectForKey:key]) {
			[observation cancel];
		}
		[[self observers] removeObjectForKey:key];
	}
}

#pragma mark -
#pragma mark Singleton methods

+ (AGKObservationCenter*)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end