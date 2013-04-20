//
//  DTITCReportDownloadOperation.h
//  AutoIngest
//
//  Created by Oliver Drobnik on 4/20/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DTITC.h"

@class GenericAccount;
@class DTITCReportDownloadOperation;

@protocol DTITCReportDownloadOperationDelegate <NSObject>

@optional
- (void)operation:(DTITCReportDownloadOperation *)operation didFailWithError:(NSError *)error;

@end




@interface DTITCReportDownloadOperation : NSOperation

- (id)initForReportsOfType:(ITCReportType)reportType subType:(ITCReportSubType)reportSubType dateType:(ITCReportDateType)reportDateType fromAccount:(GenericAccount *)account vendorID:(NSString *)vendorID intoFolder:(NSString *)folder;

@property (nonatomic, weak) id <DTITCReportDownloadOperationDelegate> delegate;

@end
