//
//  DTITCReportManager.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 19.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTITCReportManager.h"
#import "AccountManager.h"

static DTITCReportManager *_sharedInstance = nil;

NSString * const DTITCReportManagerSyncDidStartNotification = @"DTITCReportManagerSyncDidStartNotification";
NSString * const DTITCReportManagerSyncDidFinishNotification = @"DTITCReportManagerSyncDidFinishNotification";


@implementation DTITCReportManager
{
    BOOL _synching;
    
    NSString *_reportFolder;
    NSString *_vendorID;
    
    NSOperationQueue *_queue;
}

+ (DTITCReportManager *)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[DTITCReportManager alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
        
        // load initial defaults
        [self defaultsDidUpdate:nil];
        
        // observe for defaults changes, e.g. download path
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsDidUpdate:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)_downloadAllReportsOfType:(ITCReportType)reportType subType:(ITCReportSubType)reportSubType dateType:(ITCReportDateType)reportDateType fromAccount:(GenericAccount *)account
{
    BOOL downloadAll = YES;
    
    // determine date to pass to download
    __block NSDate *reportDate;
    NSDate *today = [NSDate date];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setDay:-1];
    
    reportDate = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:today options:0];
    
    // for weekly reports go back to previous Sunday
    if (reportDateType == ITCReportDateTypeWeekly)
    {
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        
        NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate:reportDate];
        
        if (comps.weekday!=1) // not a Sunday
        {
            comps.day = -(comps.weekday-1);
            comps.weekday = 0;
            
            reportDate = [gregorian dateByAddingComponents:comps toDate:reportDate options:0];
        }
    }
    
    // create a downloader
    DTITCReportDownloader *downloader = [[DTITCReportDownloader alloc] initWithUser:account.account password:account.password vendorIdentifier:_vendorID];
    
    __block NSUInteger downloadedFiles = 0;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSString *dateFormat = NSStringWithDateFormatForITCReportDateType(reportDateType);
    
    [formatter setDateFormat:dateFormat];
    
    do
    {
        NSString *predictedName = [downloader predictedFileNameForDate:reportDate
                                                            reportType:reportType
                                                        reportDateType:reportDateType
                                                         reportSubType:reportSubType
                                                            compressed:YES];
        
        NSString *predictedOutputPath = [_reportFolder stringByAppendingPathComponent:predictedName];
        
        if ([fileManager fileExistsAtPath:predictedOutputPath])
        {
            NSLog(@"Skipped %@ because it already exists at %@", predictedName, _reportFolder);
            downloadedFiles++;
            
            if (!downloadAll)
            {
                break;
            }
        }
        else if ([downloader downloadReportWithDate:reportDate
                                         reportType:reportType
                                     reportDateType:reportDateType
                                      reportSubType:reportSubType
                                  completionHandler:^(NSString *fileName, NSData *data) {
                                      NSString *baseName = [fileName stringByReplacingOccurrencesOfString:@".txt.gz" withString:@""];
                                      
                                      // update actual report date
                                      NSString *dateFormat = NSStringWithDateFormatForITCReportDateType(reportDateType);
                                      
                                      NSString *dateStringInName = [baseName substringWithRange:NSMakeRange([baseName length]-[dateFormat length], [dateFormat length])];
                                      formatter.dateFormat = dateFormat;
                                      NSDate *parsedDate = [formatter dateFromString:dateStringInName];
                                      
                                      if ([parsedDate compare:reportDate] == NSOrderedDescending)
                                      {
                                          // cancel loop, this file does not fit with what we requested
                                          reportDate = nil;
                                          
                                          return;
                                      }
                                      else
                                      {
                                          reportDate = parsedDate;
                                      }
                                      
                                      // get current working directory
                                      NSString *outputPath = [_reportFolder stringByAppendingPathComponent:fileName];
                                      
                                      // skip this file if output already exists
                                      if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
                                      {
                                          NSLog(@"Skipped %@ because it already exists at %@", predictedName, _reportFolder);
                                          downloadedFiles++;
                                          
                                          return;
                                      }
                                      
                                      // write data to file
                                      NSError *writeError = nil;
                                      if ([data writeToFile:outputPath options:NSDataWritingAtomic error:&writeError])
                                      {
                                          printf("%s\n", [fileName UTF8String]);
                                          downloadedFiles++;
                                      }
                                      else
                                      {
                                          printf("%s\n", [[writeError localizedDescription] UTF8String]);
                                      }
                                  }
                  
                                       errorHandler:^(NSError *error) {
                                           if (!downloadAll)
                                           {
                                               // don't output single file errors for ALL mode
                                               printf("%s\n", [[error localizedDescription] UTF8String]);
                                           }
                                       }])
        {
            // download succeeded for this date
            if (!downloadAll)
            {
                break;
            }
        }
        else
        {
            // download failed for this date
            if (!downloadAll)
            {
                // abort for single file
                break;
            }
            else
            {
                if (downloadedFiles>0)
                {
                    // if we are downloading all the first failure means we end
                    break;
                }
            }
        }
        
        if (downloadAll)
        {
            // move to one day/week/month/year earlier
            NSDateComponents *comps = [[NSDateComponents alloc] init];
            
            switch (reportDateType)
            {
                case ITCReportDateTypeDaily:
                {
                    [comps setDay:-1];
                    break;
                }
                    
                case ITCReportDateTypeWeekly:
                {
                    [comps setDay:-7];
                    break;
                }
                    
                case ITCReportDateTypeMonthly:
                {
                    [comps setMonth:-1];
                    break;
                }
                    
                case ITCReportDateTypeYearly:
                {
                    [comps setYear:-1];
                    break;
                }
                    
                default:
                {
                    break;
                }
            }
            
            if (!reportDate)
            {
                break;
            }
            
            reportDate = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:reportDate options:0];
        }
        
    } while (1);
}


- (void)startSync
{
    if (_synching)
    {
        NSLog(@"Already Synching");
        return;
    }

    NSArray *accounts = [[AccountManager sharedAccountManager] accountsOfType:@"iTunes Connect"];
    
    if (![accounts count])
    {
        NSLog(@"No account configured");
        return;
    }
    
    // only one account support initially
    GenericAccount *account = accounts[0];
    
    if (!account.password)
    {
        NSLog(@"Account configured, but no password set");
        return;
    }
    
    if (![_vendorID integerValue] || (![_vendorID hasPrefix:@"8"]))
    {
        NSLog(@"Invalid Vendor ID, must be numeric and begin with an 8");
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    __weak DTITCReportManager *weakself = self;
    
    BOOL hasWorkToDo = NO;
    
    if ([defaults boolForKey:@"DownloadDaily"])
    {
        [_queue addOperationWithBlock:^{
            [weakself _downloadAllReportsOfType:ITCReportTypeSales subType:ITCReportSubTypeSummary dateType:ITCReportDateTypeDaily fromAccount:account];
        }];
        
        hasWorkToDo = YES;
    }
    
    if ([defaults boolForKey:@"DownloadWeekly"])
    {
        [_queue addOperationWithBlock:^{
            [weakself _downloadAllReportsOfType:ITCReportTypeSales subType:ITCReportSubTypeSummary dateType:ITCReportDateTypeWeekly fromAccount:account];
        }];
        
        hasWorkToDo = YES;
    }
    
    if ([defaults boolForKey:@"DownloadMonthly"])
    {
        [_queue addOperationWithBlock:^{
            [weakself _downloadAllReportsOfType:ITCReportTypeSales subType:ITCReportSubTypeSummary dateType:ITCReportDateTypeMonthly fromAccount:account];
        }];
        
        hasWorkToDo = YES;
    }
    
    if ([defaults boolForKey:@"DownloadYearly"])
    {
        [_queue addOperationWithBlock:^{
            [weakself _downloadAllReportsOfType:ITCReportTypeSales subType:ITCReportSubTypeSummary dateType:ITCReportDateTypeYearly fromAccount:account];
        }];
        
        hasWorkToDo = YES;
    }
    
    if (!hasWorkToDo)
    {
        NSLog(@"Nothing to do for synching!");
        return;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:DTITCReportManagerSyncDidStartNotification object:weakself];
    
    // completion
    [_queue addOperationWithBlock:^{
        [weakself stopSync];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:DTITCReportManagerSyncDidFinishNotification object:weakself];
    }];
}

- (void)stopSync
{
    if (!_synching)
    {
        return;
    }

    [_queue cancelAllOperations];
    
    _synching = NO;
}

#pragma mark - Notifications

- (void)defaultsDidUpdate:(NSNotification *)notification
{
    NSString *reportFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadFolderPath"];
    
    if ([_reportFolder isEqualToString:reportFolder])
    {
        return;
    }
    
    // need to stop synch, folder changed
    if (_synching)
    {
        [self stopSync];
    }

    NSLog(@"Report Download Folder changed to %@", reportFolder);
    _reportFolder = reportFolder;
    
    _vendorID = [[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadVendorID"];
}

@end
