//
//  Created by Felipe Cypriano on 27/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface ReportOrganizer : NSObject

+ (ReportOrganizer *)sharedOrganizer;

- (void)startMonitoringDownloadFolder;
- (void)stopMonitoringDownloadFolder;

@end