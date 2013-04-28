//
//  NSDate+JXOffset.h
//  AutoIngest
//
//  Created by Jan on 28.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (JXOffset)

- (NSDate *)dateWithDayOffset:(NSInteger)dayOffset;
- (NSDate *)dateWithDayOffset:(NSInteger)dayOffset justBeforeMidnight:(BOOL)justBeforeMidnight;

@end
