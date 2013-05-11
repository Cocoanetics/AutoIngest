//
//  ReportFolderClassifierTests.m
//  AutoIngest
//
//  Created by Felipe Cypriano on 22/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "ReportFolderClassifier.h"

@interface ReportFolderClassifierTests : SenTestCase
@end


@implementation ReportFolderClassifierTests {
    ReportFolderClassifier *classifier;
}

- (void)setUp
{
    classifier = [[ReportFolderClassifier alloc] init];
}

- (void)testIfReturnsCorrectPathForASalesSummaryDailyReports
{
    NSString *expectedPath = @"81234567/Sales/Summary/Daily/";
    NSString *path = [classifier pathForReportFileName:@"S_D_81234567_20130101.txt.gz"];
    STAssertEqualObjects(path, expectedPath, @"Wrong path for a daily summary sales report");
}

- (void)testIfReturnsCorrectPathForASalesSummaryWeeklyReports
{
    NSString *expectedPath = @"81234567/Sales/Summary/Weekly/";
    NSString *path = [classifier pathForReportFileName:@"S_W_81234567_20130101.txt.gz"];
    STAssertEqualObjects(path, expectedPath, @"Wrong path for a daily summary sales report");
}

- (void)testIfReturnsCorrectPathForASalesSummaryMonthlyReports
{
    NSString *expectedPath = @"81234567/Sales/Summary/Monthly/";
    NSString *path = [classifier pathForReportFileName:@"S_M_81234567_20130101.txt.gz"];
    STAssertEqualObjects(path, expectedPath, @"Wrong path for a daily summary sales report");
}

- (void)testIfReturnsCorrectPathForASalesSummaryYearlyReports
{
    NSString *expectedPath = @"81234567/Sales/Summary/Yearly/";
    NSString *path = [classifier pathForReportFileName:@"S_Y_81234567_20130101.txt.gz"];
    STAssertEqualObjects(path, expectedPath, @"Wrong path for a daily summary sales report");
}

#pragma mark - Base Path

- (void)testIfSetBasePathAddsAForwardSlashAtTheEndIfThereIsNotOneAlready
{
    classifier.basePath = @"/ThePath";
    STAssertEqualObjects(classifier.basePath, @"/ThePath/", @"Should add a forward slash at the end of the base path");
}

- (void)testPrependBasePathToTheReportPath
{
    NSString *expectedPath = @"/Users/user/Dropbox/81234567/Sales/Summary/Yearly/";
    classifier.basePath = @"/Users/user/Dropbox/";
    NSString *path = [classifier pathForReportFileName:@"S_Y_81234567_20130101.txt.gz"];
    STAssertEqualObjects(path, expectedPath, @"Base path should have been prepended");
}

@end
