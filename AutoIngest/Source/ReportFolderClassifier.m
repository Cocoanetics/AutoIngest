//
//  Created by Felipe Cypriano on 22/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//


#import "ReportFolderClassifier.h"
#import "ReportInformation.h"


@implementation ReportFolderClassifier {

    NSString *_basePath;
}

- (id)initWithBasePath:(NSString *)basePath
{
    self = [self init];
    if (self)
    {
        self.basePath = [basePath copy];
    }
    return self;
}

- (NSString *)pathForReportFileName:(NSString *)filename
{
    NSString *path;
    ReportInformation *reportInfo = [ReportInformation reportInformationFromFilename:filename];
    if (reportInfo)
    {
        path = [self.basePath stringByAppendingFormat:@"%li/%@/%@/%@/",
                                                      reportInfo.vendorId,
                                                      [reportInfo typeStringValue],
                                                      [reportInfo subTypeStringValue],
                                                      [reportInfo dateTypeStringValue]];
    }

    return path;
}

#pragma mark - Properties

- (void)setBasePath:(NSString *)basePath
{
    if (basePath != _basePath)
    {
        if (basePath)
        {
            NSString *last = [basePath substringFromIndex:[basePath length] - 1];
            if (![last isEqualToString:@"/"])
            {
                basePath = [basePath stringByAppendingFormat:@"/"];
            }
        }

        _basePath = [basePath copy];
    }
}

- (NSString *)basePath
{
    return _basePath != nil ? _basePath : @"";
}


@end