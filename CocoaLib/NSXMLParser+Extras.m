//
//  NSXMLParser+Extras.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-05-10.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSXMLParser+Extras.h"
#import "NSArray+Extras.h"

@interface _DictionaryParserDelegate : NSObject<NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableArray *stack;
@property (nonatomic, strong) NSMutableDictionary *current;
@property (nonatomic, strong) NSMutableDictionary *dictionary;
@end

@implementation NSXMLParser(Extras)
- (NSDictionary *)dictionary 
{
	_DictionaryParserDelegate *parseDelegate = [[_DictionaryParserDelegate alloc] init];
	[self setDelegate:parseDelegate];
	if (![self parse]) {
		[self setDelegate:nil];
		return nil;
	}
	NSDictionary *result = [parseDelegate dictionary];		
	[self setDelegate:nil];
	return result;
}
@end

@implementation _DictionaryParserDelegate 

@synthesize stack = _stack, current = _current, dictionary = _dictionary;

- (void)parserDidStartDocument:(NSXMLParser *)parser
{	
	[self setDictionary:[[NSMutableDictionary alloc] initWithCapacity:10]];	
	[self setStack:[[NSMutableArray alloc] initWithCapacity:10]];
	[self setCurrent:[self dictionary]];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict 
{
	[[self stack] addObject:[self current]];
	NSMutableDictionary *newValue = [[NSMutableDictionary alloc] initWithCapacity:3];
	id currentObject = [[self current] objectForKey:elementName];
	if (currentObject) {
		if ([currentObject isKindOfClass:[NSDictionary class]]) {
			NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:3];
			[newArray addObject:currentObject];
			[newArray addObject:newValue];
			[[self current] setObject:newArray forKey:elementName];
		} else {
			[currentObject addObject:newValue];
		}
	} else {
		[[self current] setObject:newValue forKey:elementName];
	}
	[newValue addEntriesFromDictionary:attributeDict];
	[self setCurrent:newValue];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	NSString *text = [[self current] objectForKey:@"_text"];
	[[self current] setObject:(text ? [text stringByAppendingString:string] : string) forKey:@"_text"];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	[self setCurrent:[[self stack] lastObject]];
	[[self stack] removeLastObject];
}

@end