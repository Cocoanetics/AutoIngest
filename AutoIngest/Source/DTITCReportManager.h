//
//  DTITCReportManager.h
//  AutoIngest
//
//  Created by Oliver Drobnik on 19.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const DTITCReportManagerSyncDidStartNotification;
extern NSString * const DTITCReportManagerSyncDidFinishNotification;

@interface DTITCReportManager : NSObject

+ (DTITCReportManager *)sharedManager;

- (void)startSync;

- (void)stopSync;

@end
