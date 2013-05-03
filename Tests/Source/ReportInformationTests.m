//
//  ReportInformationTests.m
//  AutoIngest
//
//  Created by Felipe Cypriano on 04/22/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "ReportInformation.h"

@interface ReportInformationTests : SenTestCase
@end


@implementation ReportInformationTests {
    ReportInformation *reportInformation;
}

- (void)setUp
{
    reportInformation = [[ReportInformation alloc] init];
}

#pragma mark - reportInformationFromFilename:

- (void)testIfTypePropertyIsCorrectForSalesReport
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"S_W_81234567_20121024.txt.gz"];
    STAssertEquals(reportInfo.type, ITCReportTypeSales, @"Wrong report type");
}

- (void)testIfSubtypePropertyIsCorrectForSalesReport
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"S_W_81234567_20121024.txt.gz"];
    STAssertEquals(reportInfo.subType, ITCReportSubTypeSummary, @"Wrong report sub type");
}

- (void)testIfDateTypePropertyIsCorrectForYearlySalesReport
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"S_Y_81234567_20130422"];
    STAssertEquals(reportInfo.dateType, ITCReportDateTypeYearly, @"Wrong report date type");
}

- (void)testIfDateTypePropertyIsCorrectForMonthlySalesReport
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"S_M_81234567_20130422"];
    STAssertEquals(reportInfo.dateType, ITCReportDateTypeMonthly, @"Wrong report date type");
}

- (void)testIfDateTypePropertyIsCorrectForWeeklySalesReport
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"S_W_81234567_20130422"];
    STAssertEquals(reportInfo.dateType, ITCReportDateTypeWeekly, @"Wrong report date type");
}

- (void)testIfDateTypePropertyIsCorrectForDailyNewsstandReport
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"N_D_D_80000000_20121024"];
    STAssertEquals(reportInfo.dateType, ITCReportDateTypeDaily, @"Wrong report date type");
}

- (void)testIfVendorIdPropertyIsCorrect
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"S_Y_81234567_20130422"];
    STAssertEquals(reportInfo.vendorId, (NSInteger) 81234567, @"Wrong report vendor id");
}

- (void)testIfTypePropertyIsCorrectForNewsstandReport
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"N_D_D_80000000_20121024.txt.gz"];
    STAssertEquals(reportInfo.type, ITCReportTypeNewsstand, @"Wrong report type");
}

- (void)testIfSubtypePropertyIsCorrectForNewsstandReport
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"N_D_D_80000000_20121024.txt.gz"];
    STAssertEquals(reportInfo.subType, ITCReportSubTypeDetailed, @"Wrong report sub type");
}

- (void)testIfTypePropertyIsCorrectForOptInReport
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"O_S_D_80000000_20121024.txt.gz"];
    STAssertEquals(reportInfo.type, ITCReportTypeOptIn, @"Wrong report type");
}

- (void)testIfSubtypePropertyIsCorrectForOptInReport
{
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFileName:@"O_S_D_80000000_20121024.txt.gz"];
    STAssertEquals(reportInfo.subType, ITCReportSubTypeSummary, @"Wrong report sub type");
}

#pragma mark - typeStringValue

- (void)testIfTypeStringValueIsCorrectForSalesReport
{
    reportInformation.type = ITCReportTypeSales;
    STAssertEqualObjects([reportInformation typeStringValue], @"Sales", @"Wrong type string for Sales report");
}

- (void)testIfTypeStringValueIsCorrectForNewsstandReport
{
    reportInformation.type = ITCReportTypeNewsstand;
    STAssertEqualObjects([reportInformation typeStringValue], @"Newsstand", @"Wrong type string for Newsstand report");
}

- (void)testIfTypeStringValueIsCorrectForOptInReport
{
    reportInformation.type = ITCReportTypeOptIn;
    STAssertEqualObjects([reportInformation typeStringValue], @"Opt-In", @"Wrong type string for OptIn report");
}

#pragma mark - subTypeStringValue

- (void)testIfSubTypeStringValueIsCorrectForSummaryReport
{
    reportInformation.subType = ITCReportSubTypeSummary;
    STAssertEqualObjects([reportInformation subTypeStringValue], @"Summary", @"Wrong string for Summary sub type");
}

- (void)testIfSubTypeStringValueIsCorrectForSummaryDetailed
{
    reportInformation.subType = ITCReportSubTypeDetailed;
    STAssertEqualObjects([reportInformation subTypeStringValue], @"Detailed", @"Wrong string for Detailed sub type");
}

#pragma mark - dateTypeStringValue

- (void)testIfDateTypeStringValueIsCorrectForDaily
{
    reportInformation.dateType = ITCReportDateTypeDaily;
    STAssertEqualObjects([reportInformation dateTypeStringValue], @"Daily", @"Wrong string for Daily date type");
}

- (void)testIfDateTypeStringValueIsCorrectForWeekly
{
    reportInformation.dateType = ITCReportDateTypeWeekly;
    STAssertEqualObjects([reportInformation dateTypeStringValue], @"Weekly", @"Wrong string for Weekly date type");
}

- (void)testIfDateTypeStringValueIsCorrectForMonthly
{
    reportInformation.dateType = ITCReportDateTypeMonthly;
    STAssertEqualObjects([reportInformation dateTypeStringValue], @"Monthly", @"Wrong string for Monthly date type");
}

- (void)testIfDateTypeStringValueIsCorrectForYearly
{
    reportInformation.dateType = ITCReportDateTypeYearly;
    STAssertEqualObjects([reportInformation dateTypeStringValue], @"Yearly", @"Wrong string for Yearly date type");
}

#pragma mark -  isFileNameAReport:

- (void)testValidFileNamesReports
{
    void (^testFileName)(NSString *) = ^(NSString *fileName){
        STAssertTrue([ReportInformation isFileNameAReport:fileName], @"'%@' should be valid", fileName);
    };

    testFileName(@"S_Y_81234567_2012.txt.gz");
    testFileName(@"S_M_81234567_201208.txt.gz");
    testFileName(@"S_D_81234567_20120812.txt.gz");
}

- (void)testNonFileNamesReports
{
    void (^testFileName)(NSString *) = ^(NSString *fileName){
        STAssertFalse([ReportInformation isFileNameAReport:fileName], @"'%@' should not be valid", fileName);
    };

    testFileName(@"S_Y_81234567_2012.gz");
    testFileName(@"S_M_8123456_201208.txt.gz");
    testFileName(@"S_D_81234567_12.txt");
}

@end
