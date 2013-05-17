//
//  NSString+AutoIngest.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 5/17/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "NSString+AutoIngest.h"

@implementation NSString (AutoIngest)

- (BOOL)isValidVendorIdentifier
{
	NSString *vendorRegEx = @"8\\d{7}";
	NSPredicate *vendorIdPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", vendorRegEx];
	return [vendorIdPredicate evaluateWithObject:self];
}

@end
