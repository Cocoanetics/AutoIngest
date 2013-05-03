//
//  Created by Felipe Cypriano on 22/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//


#import "ReportInformation.h"

static NSString *const kCheckFileNameIsAReportRegexPattern = @"(S|O_S|N_D)_(D|W|M|Y)_(\\d{8})_(\\d{4,8})\\.(txt(\\.gz)?)";
static NSString *const kObtainReportDataFromFileNameRegexPattern = @"(S|O_S|N_D)_(D|W|M|Y)_(\\d{8})";

@implementation ReportInformation {

}

static NSCache *_cache;

+ (void)initialize
{
    _cache = [[NSCache alloc] init];
}


+ (BOOL)isFileNameAReport:(NSString *)fileName
{
    NSRegularExpression *regex = [_cache objectForKey:kCheckFileNameIsAReportRegexPattern];
    if (!regex)
    {
        NSError *error = nil;
        regex = [NSRegularExpression regularExpressionWithPattern:kCheckFileNameIsAReportRegexPattern
                                                                               options:0 error:&error];
        [_cache setObject:regex forKey:kCheckFileNameIsAReportRegexPattern];
        if (error)
        {
            NSLog(@"Error creating regular expression '%@'. Cause: %@", kCheckFileNameIsAReportRegexPattern, error);
        }
    }

    NSRange range = NSMakeRange(0, [fileName length]);
    return [regex numberOfMatchesInString:fileName options:0 range:range] > 0;
}


+ (ReportInformation *)reportInformationFromFileName:(NSString *)fileName
{
    NSRegularExpression *regex = [_cache objectForKey:kObtainReportDataFromFileNameRegexPattern];
    if (!regex)
    {
        NSError *regexError = nil;
        regex = [NSRegularExpression regularExpressionWithPattern:kObtainReportDataFromFileNameRegexPattern options:0 error:&regexError];
        [_cache setObject:regex forKey:kObtainReportDataFromFileNameRegexPattern];
        if (regexError)
        {
            NSLog(@"Error creating regular expression '%@'. Cause: %@", kObtainReportDataFromFileNameRegexPattern, regexError);
            return nil;
        }
    }

    ReportInformation *reportInformation;
    NSRange range = NSMakeRange(0, [fileName length]);
    NSTextCheckingResult *match = [regex firstMatchInString:fileName options:0 range:range];
    if ([match numberOfRanges] == 4)
    {
        reportInformation = [[ReportInformation alloc] init];
        NSString *typeChar = [fileName substringWithRange:[match rangeAtIndex:1]];
        [reportInformation _setTypeFromFilenameChar:typeChar];
        NSString *dateChar = [fileName substringWithRange:[match rangeAtIndex:2]];
        [reportInformation _setDateTypeFromFilenameChar:dateChar];
        NSString *vendorId = [fileName substringWithRange:[match rangeAtIndex:3]];
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