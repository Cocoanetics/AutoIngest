//
//  Created by Felipe Cypriano on 27/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//


#import "ReportOrganizer.h"

// FSEventStreamCallback
void eventStreamCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@implementation ReportOrganizer {
    NSString *_downloadFolder;
    BOOL _isMonitoring;
    FSEventStreamRef _eventStream;
    dispatch_queue_t _serialQueue;
}

+ (ReportOrganizer *)sharedOrganizer
{
    static ReportOrganizer *sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[ReportOrganizer alloc] initPrivate];
    });
    return sharedInstance;
}

- (id)initPrivate
{
    self = [super init];
    if (self)
    {
        _serialQueue = dispatch_queue_create("com.dropbnik.autoingest.reportorganizer", DISPATCH_QUEUE_SERIAL);

        _downloadFolder = [[NSUserDefaults standardUserDefaults] stringForKey:AIUserDefaultsDownloadFolderPathKey];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsDidUpdate:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
                         
    return self;
}

- (id)init
{
    [[NSException exceptionWithName:@"Singleton" reason:@"Use the sharedOrganizer method instead" userInfo:nil] raise];
    return nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_isMonitoring)
    {
        [self stopMonitoringDownloadFolder];
    }

    dispatch_release(_serialQueue);
}

#pragma mark - Public API

- (void)startMonitoringDownloadFolder
{
    dispatch_sync(_serialQueue, ^{
        if (_isMonitoring) return;

        CFArrayRef pathsToWatch = (__bridge CFArrayRef) @[_downloadFolder];
        _eventStream = FSEventStreamCreate(NULL,
                &eventStreamCallback,
                NULL,
                pathsToWatch,
                kFSEventStreamEventIdSinceNow,
                10.0,
                kFSEventStreamCreateFlagNone);

        FSEventStreamScheduleWithRunLoop(_eventStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        FSEventStreamStart(_eventStream);

        _isMonitoring = YES;
    });
}

- (void)stopMonitoringDownloadFolder
{
    dispatch_sync(_serialQueue, ^{
        if (!_isMonitoring) return;

        FSEventStreamStop(_eventStream);
        FSEventStreamInvalidate(_eventStream);
        FSEventStreamRelease(_eventStream);
        _eventStream = NULL;

        _isMonitoring = NO;
    });
}

#pragma - Private Methods
    
- (void)defaultsDidUpdate:(NSNotification *)notification
{
    __weak ReportOrganizer *weakSelf = self;

    dispatch_sync(_serialQueue, ^{
        NSString *reportFolder = [[NSUserDefaults standardUserDefaults] objectForKey:AIUserDefaultsDownloadFolderPathKey];

        if (![_downloadFolder isEqualToString:reportFolder])
        {
            NSLog(@"ReportOrganizer: Download Folder changed to %@", reportFolder);
            _downloadFolder = reportFolder;
            if (_isMonitoring)
            {
                [weakSelf stopMonitoringDownloadFolder];
                [weakSelf startMonitoringDownloadFolder];
            }
        }
    });
}

- (void)organizeAllReports
{
    dispatch_sync(_serialQueue, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error = nil;
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:_downloadFolder error:&error];
        if (error)
        {
            NSLog(@"Couldn't get contents of directory '%@'. Error %@", _downloadFolder, error);
            return;
        }

        NSLog(@"%@ - contents %@", [NSDate date], contents);
        // TODO do the organization
    });
}


@end


#pragma mark - FSEventStreamCallback

void eventStreamCallback(
    ConstFSEventStreamRef streamRef,
    void *clientCallBackInfo,
    size_t numEvents,
    void *eventPaths,
    const FSEventStreamEventFlags eventFlags[],
    const FSEventStreamEventId eventIds[])
{
    [[ReportOrganizer sharedOrganizer] organizeAllReports];
}