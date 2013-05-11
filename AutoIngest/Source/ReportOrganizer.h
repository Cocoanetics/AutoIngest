//
//  ReportOrganizer.m
//  AutoIngest
//
//  Created by Felipe Cypriano on 30/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

@interface ReportOrganizer : NSObject

+ (ReportOrganizer *)sharedOrganizer;

- (void)organizeAllReports;

@end