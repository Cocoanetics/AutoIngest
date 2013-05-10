//
//  ReportDownloadFolderMonitor.h
//  AutoIngest
//
//  Created by Felipe Cypriano on 27/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

@interface ReportDownloadFolderMonitor : NSObject

+ (ReportDownloadFolderMonitor *)sharedMonitor;

- (void)startMonitoring;
- (void)stopMonitoring;
- (BOOL)isMonitoring;

@end