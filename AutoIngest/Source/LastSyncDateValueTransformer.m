//
//  LastSyncDateValueTransformer.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 4/21/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "LastSyncDateValueTransformer.h"

@implementation LastSyncDateValueTransformer

+ (Class)transformedValueClass
{
	return [NSString class];
}

- (id)transformedValue:(id)value
{
	if (!value)
	{
		return @"Last Sync: Never";
	}
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	
	return [NSString stringWithFormat:@"Last Sync: %@", [dateFormatter stringFromDate:value]];
}

@end
