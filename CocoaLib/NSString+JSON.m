//
//  NSString+JSON.m
//  CocoaLib
//
//  Created by Christoffer Lernö on 2010-21-09.
//  Copyright 2010 Aegik AB. All rights reserved.
//

#import "NSString+JSON.h"
#import "AGK.h"

@interface NSScanner(JSON)
- (NSDictionary *)scanObject;
- (NSString *)scanString;
- (NSArray *)scanArray;
- (NSNumber *)scanNumber;
@end

@implementation NSString(JSON)
- (NSDictionary *)jsonDecode {
	NSScanner *scanner = [[NSScanner alloc] initWithString:self];
	[scanner setCharactersToBeSkipped:nil];
	id object = [scanner scanObject];
	return object;
}
@end

@implementation NSData(JSON)
- (NSDictionary *)jsonDecode:(NSStringEncoding)encoding {
	NSString *string = [[NSString alloc] initWithData:self encoding:encoding];
	NSDictionary *result = [string jsonDecode];
	return result;
}

- (NSDictionary *)jsonDecode {
	return [self jsonDecode:NSUTF8StringEncoding];	
}

@end


@implementation NSScanner(JSON)

- (NSString *)scanString {
	if (![self scanString:@"\"" intoString:NULL]) {
		AGKTrace(@"String did not begin with \"");
		return nil;
	}
	NSString *parsed = nil;
	NSMutableString *mutableString = nil;
	static NSCharacterSet *stopCharacters = nil;
	if (!stopCharacters) stopCharacters = [NSCharacterSet characterSetWithCharactersInString:@"\\\""];
	while (true) {
		
		if (!mutableString && parsed) {
			mutableString = [NSMutableString stringWithString:parsed];
		}
		
		if (![self scanUpToCharactersFromSet:stopCharacters intoString:&parsed]) parsed = @"";
		
		if (mutableString) {
			[mutableString appendString:parsed];
			parsed = mutableString;
		}
		
		if ([self scanString:@"\"" intoString:NULL]) return parsed;
		
		[self scanString:@"\\" intoString:NULL];
		
		if ([self isAtEnd]) {
			AGKTrace(@"String not terminated");
			return nil;
		}
		if (!mutableString) mutableString = [NSMutableString stringWithString:parsed];
		unichar c = [[self string] characterAtIndex:[self scanLocation]];
		[self setScanLocation:[self scanLocation] + 1];
		switch (c) {
			case '"':
				[mutableString appendString:@"\""];
				break;
			case '\\':
				[mutableString appendString:@"\\"];
				break;
			case '/':
				[mutableString appendString:@"/"];
				break;
			case 'b':
				[mutableString appendString:@"\b"];
				break;
			case 'f':
				[mutableString appendString:@"\f"];
				break;
			case 'n':
				[mutableString appendString:@"\n"];
				break;
			case 'r':
				[mutableString appendString:@"\r"];
				break;
			case 't':
				[mutableString appendString:@"\t"];
				break;
			case 'u':
			{
				unichar number = 0;
				for (unsigned int i = 0; i < 4; i++) {
					number <<= 4;
					unichar u = [[self string] characterAtIndex:[self scanLocation] + i];
					if (u >= '0' && u <= '9') {
						number += u - '0';
					} else if (u >= 'a' && u <= 'f') {
						number += u - 'a' + 10;
					} else if (u >= 'A' && u <= 'F') {
						number += u - 'A' + 10;
					} else {
						AGKTrace(@"Illegal unicode");
						return nil;
					}
				}
				[self setScanLocation:[self scanLocation] + 4];
				[mutableString appendFormat:@"%C", number];
				break;
			}
			default:
				AGKTrace(@"Unexpected escape-character");
				return nil;
		}
	}
	
}

- (NSNumber *)scanNumber {
	NSDecimal number;
	if (![self scanDecimal:&number]) return nil;
	return [NSDecimalNumber decimalNumberWithDecimal:number];
}

- (id)scanValue {
	if ([self isAtEnd]) {
		AGKTrace(@"Reached end reading value");
		return nil;
	}
	unichar c = [[self string] characterAtIndex:[self scanLocation]];
	switch (c) {
		case '"':
			return [self scanString];
		case '{':
			return [self scanObject];
		case '[':
			return [self scanArray];
		default:
			break;
	}
	if ([self scanString:@"null" intoString:NULL]) return [NSNull null];
	if ([self scanString:@"true" intoString:NULL]) return [NSNumber numberWithBool:YES];
	if ([self scanString:@"false" intoString:NULL]) return [NSNumber numberWithBool:NO];
	return [self scanNumber];
}

- (NSArray *)scanArray {
    static NSCharacterSet *notWhitespace = nil;
    if (!notWhitespace) notWhitespace = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
    [self scanUpToCharactersFromSet:notWhitespace intoString:NULL];
	if (![self scanString:@"[" intoString:NULL]) {
		AGKTrace(@"Failed to find the beginning of array");
		return nil;
	}
	[self scanUpToCharactersFromSet:notWhitespace intoString:NULL];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:16];
	if ([self scanString:@"]" intoString:NULL]) return array;
	while(true) {
		id value = [self scanValue];
		if (!value) {
			AGKTrace(@"Failed to find array entry");
			return nil;
		}
		[array addObject:value];
        [self scanUpToCharactersFromSet:notWhitespace intoString:NULL];
		if (![self scanString:@"," intoString:NULL]) {
			if (![self scanString:@"]" intoString:NULL]) {
				AGKTrace(@"Array not ending with ']'");
				return nil;
			}
			return array;
		}
        [self scanUpToCharactersFromSet:notWhitespace intoString:NULL];
    }
}

- (NSDictionary *)scanObject {
    static NSCharacterSet *notWhitespace = nil;
    if (!notWhitespace) notWhitespace = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
	[self scanUpToCharactersFromSet:notWhitespace intoString:NULL];
	if (![self scanString:@"{" intoString:NULL]) return nil;
	[self scanUpToCharactersFromSet:notWhitespace intoString:NULL];
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:16];
	if ([self scanString:@"}" intoString:NULL]) return dictionary;
	while(true) {
		NSString *string = [self scanString];
		if (!string) return nil;
        [self scanUpToCharactersFromSet:notWhitespace intoString:NULL];
		if (![self scanString:@":" intoString:NULL]) {
			AGKTrace(@"Failed to find ':' after key");
			return nil;
		}
        [self scanUpToCharactersFromSet:notWhitespace intoString:NULL];
		id value = [self scanValue];
		if (!value) {
			AGKTrace(@"Failed to find value");
			return nil;
		}
		if (value != [NSNull null]) {
			[dictionary setObject:value forKey:string];
		}
        [self scanUpToCharactersFromSet:notWhitespace intoString:NULL];
		if (![self scanString:@"," intoString:NULL]) {
			if (![self scanString:@"}" intoString:NULL]) {
				AGKTrace(@"Object not ending with '}'");
				return nil;
			}
			return dictionary;
		}
        [self scanUpToCharactersFromSet:notWhitespace intoString:NULL];
    }
}

@end