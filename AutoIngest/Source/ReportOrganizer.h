//
//  Created by Felipe Cypriano on 30/04/13.
//
//


#import <Foundation/Foundation.h>


@interface ReportOrganizer : NSObject

+ (ReportOrganizer *)sharedOrganizer;

- (void)organizeAllReports;

@end