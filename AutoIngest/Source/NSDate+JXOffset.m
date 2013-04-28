//
//  NSDate+JXOffset.m
//  AutoIngest
//
//  Created by Jan on 28.04.13.
//  Copyright (c) 2013 geheimwerk.de. All rights reserved.
//

#import "NSDate+JXOffset.h"

@implementation NSDate (JXOffset)

- (NSDate *)dateWithDayOffset:(NSInteger)dayOffset;
{
	return [self dateWithDayOffset:dayOffset justBeforeMidnight:NO];
}

- (NSDate *)dateWithDayOffset:(NSInteger)dayOffset justBeforeMidnight:(BOOL)justBeforeMidnight;
{
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	
	NSDateComponents *components = [[NSDateComponents alloc] init];
	components.day = dayOffset;
	NSDate *offsetDate = [gregorian dateByAddingComponents:components toDate:self options:0];
	
	if (justBeforeMidnight) {
		NSDateComponents *offsetDateComponents = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:offsetDate];
		
		offsetDateComponents.hour = 23;
		offsetDateComponents.minute = 59;
		offsetDateComponents.second = 59;
		NSDate *offsetDateJustBeforeMidnight = [gregorian dateFromComponents:offsetDateComponents];
		
		return offsetDateJustBeforeMidnight;
	}
	else {
		return offsetDate;
	}
}

@end
