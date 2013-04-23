//
//  Created by Felipe Cypriano on 22/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface ReportFolderClassifier : NSObject

@property (nonatomic, copy) NSString *basePath;

- (id)initWithBasePath:(NSString *)basePath;
- (NSString *)pathForReportFileName:(NSString *)filename;

@end