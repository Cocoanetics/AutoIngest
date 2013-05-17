//
//  ValidVendorValueTransformer.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 5/17/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "ValidVendorValueTransformer.h"
#import "NSString+AutoIngest.h"

@implementation ValidVendorValueTransformer


+ (Class)transformedValueClass
{
	return [NSArray class];
}

- (id)transformedValue:(id)value
{
	NSArray *array = nil;
	
	if ([value isKindOfClass:[NSArray class]])
	{
		array = value;
	}
	else if ([value isKindOfClass:[NSString class]])
	{
		array = @[value];
	}
	
	if (!value)
	{
		return nil;
	}
	
	// make unique in set
	NSMutableSet *validTokens = [NSMutableSet set];
	
	for (NSString *oneToken in array)
	{
		if ([oneToken isValidVendorIdentifier])
		{
			[validTokens addObject:oneToken];
		}
	}
	
	NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:nil
																			 ascending:YES
																			  selector:@selector(compare:)];
	return [validTokens sortedArrayUsingDescriptors:@[sort]];
}

@end
