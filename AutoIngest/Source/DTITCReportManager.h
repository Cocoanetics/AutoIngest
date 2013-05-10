//
//  DTITCReportManager.h
//  AutoIngest
//
//  Created by Oliver Drobnik on 19.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

extern NSString * const DTITCReportManagerSyncDidStartNotification;
extern NSString * const DTITCReportManagerSyncDidFinishNotification;

@interface DTITCReportManager : NSObject

@property (nonatomic) BOOL isSynching;

+ (DTITCReportManager *)sharedManager;

- (void)startSync;

- (void)stopSync;

- (BOOL)canSync;

- (void)startAutoSyncTimer;
- (void)stopAutoSyncTimer;

@end
