//
//  Created by Felipe Cypriano on 22/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface ReportInformation : NSObject

+ (BOOL)isFileNameAReport:(NSString *)fileName;
+ (ReportInformation *)reportInformationFromFileName:(NSString *)fileName;

@property (nonatomic) ITCReportType type;
@property (nonatomic) ITCReportSubType subType;
@property (nonatomic) ITCReportDateType dateType;
@property (nonatomic) NSInteger vendorId;

- (NSString *)typeStringValue;
- (NSString *)subTypeStringValue;
- (NSString *)dateTypeStringValue;

@end