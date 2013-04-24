//
//  Created by Felipe Cypriano on 22/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//


#import "ReportInformation.h"


@implementation ReportInformation {

}

+ (ReportInformation *)reportInformationFromFilename:(NSString *)filename
{
    static NSString *filenamePattern = @"(S|O_S|N_D)_(D|W|M|Y)_(\\d{8})";
    NSError *regexError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:filenamePattern options:0 error:&regexError];
    if (regexError)
    {
        NSLog(@"Error creating regular expression '%@'. Cause: %@", filenamePattern, regexError);
        return nil;
    }

    ReportInformation *reportInformation;
    NSRange range = NSMakeRange(0, [filename length]);
    NSArray *matches = [regex matchesInString:filename options:0 range:range];
    if ([matches count] > 0)
    {
        reportInformation = [[ReportInformation alloc] init];
        NSTextCheckingResult *groups = matches[0];
        NSString *typeChar = [filename substringWithRange:[groups rangeAtIndex:1]];
        [reportInformation _setTypeFromFilenameChar:typeChar];
        NSString *dateChar = [filename substringWithRange:[groups rangeAtIndex:2]];
        [reportInformation _setDateTypeFromFilenameChar:dateChar];
        NSString *vendorId = [filename substringWithRange:[groups rangeAtIndex:3]];
        reportInformation.vendorId = [vendorId integerValue];
    }

    return reportInformation;
}

- (NSString *)typeStringValue
{
    return NSStringFromITCReportType(_type);
}

- (NSString *)subTypeStringValue
{
    return NSStringFromITCReportSubType(_subType);
}

- (NSString *)dateTypeStringValue
{
    return NSStringFromITCReportDateType(_dateType);
}


#pragma mark - Private Methods

- (void)_setTypeFromFilenameChar:(NSString *)character
{
    _subType = ITCReportSubTypeSummary;

    if ([character isEqualToString:@"S"])
    {
        _type = ITCReportTypeSales;
    }
    else if ([character isEqualToString:@"N_D"])
    {
        _type = ITCReportTypeNewsstand;
        _subType = ITCReportSubTypeDetailed;
    }
    else if ([character isEqualToString:@"O_S"])
    {
        _type = ITCReportTypeOptIn;
    }
}

- (void)_setDateTypeFromFilenameChar:(NSString *)character
{
    if ([character isEqualToString:@"D"])
    {
        _dateType = ITCReportDateTypeDaily;
    }
    else if ([character isEqualToString:@"W"])
    {
        _dateType = ITCReportDateTypeWeekly;
    }
    else if ([character isEqualToString:@"M"])
    {
        _dateType = ITCReportDateTypeMonthly;
    }
    else if ([character isEqualToString:@"Y"])
    {
        _dateType = ITCReportDateTypeYearly;
    }
}

@end