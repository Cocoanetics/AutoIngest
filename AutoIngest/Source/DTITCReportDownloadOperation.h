//
//  DTITCReportDownloadOperation.h
//  AutoIngest
//
//  Created by Oliver Drobnik on 4/20/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTITC.h"

@class GenericAccount;
@class DTITCReportDownloadOperation;

@protocol DTITCReportDownloadOperationDelegate <NSObject>

@optional
- (void)operation:(DTITCReportDownloadOperation *)operation didFailWithError:(NSError *)error;

// informs the delegate of a completed download. The other parameters are available via properties
- (void)operation:(DTITCReportDownloadOperation *)operation didDownloadReportWithDate:(NSDate *)date;

@end




@interface DTITCReportDownloadOperation : NSOperation

- (id)initForReportsOfType:(ITCReportType)reportType subType:(ITCReportSubType)reportSubType dateType:(ITCReportDateType)reportDateType fromAccount:(GenericAccount *)account vendorID:(NSString *)vendorID intoFolder:(NSString *)folder;

@property (nonatomic, assign) BOOL uncompressFiles;

@property (nonatomic, weak) id <DTITCReportDownloadOperationDelegate> delegate;

@property (nonatomic, readonly) ITCReportType reportType;
@property (nonatomic, readonly) ITCReportSubType reportSubType;
@property (nonatomic, readonly) ITCReportDateType reportDateType;

@end
