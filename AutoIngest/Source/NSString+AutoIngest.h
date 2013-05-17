//
//  NSString+AutoIngest.h
//  AutoIngest
//
//  Created by Oliver Drobnik on 5/17/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (AutoIngest)


/**
 @returns `YES` if the receiver contains a valid Apple vendor identifer
 */
- (BOOL)isValidVendorIdentifier;

@end
