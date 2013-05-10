//
//  ReportDownloadFolderMonitor.m
//  AutoIngest
//
//  Created by Felipe Cypriano on 27/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "ReportDownloadFolderMonitor.h"
#import "ReportOrganizer.h"

// FSEventStreamCallback
void eventStreamCallback(ConstFSEventStreamRef streamRef, void *clientCallBackInfo, size_t numEvents, void *eventPaths, const FSEventStreamEventFlags eventFlags[], const FSEventStreamEventId eventIds[]);

@implementation ReportDownloadFolderMonitor
{
    NSString *_downloadFolder;
    BOOL _isMonitoring;
    FSEventStreamRef _eventStream;
}

+ (ReportDownloadFolderMonitor *)sharedMonitor
{
    static ReportDownloadFolderMonitor *sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [[ReportDownloadFolderMonitor alloc] initPrivate];
    });
    return sharedInstance;
}

- (id)initPrivate
{
    self = [super init];
    if (self)
    {
        _downloadFolder = [[NSUserDefaults standardUserDefaults] stringForKey:AIUserDefaultsDownloadFolderPathKey];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsDidUpdate:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
                         
    return self;
}

- (id)init
{
    [[NSException exceptionWithName:@"Singleton" reason:@"Use the sharedMonitor method instead" userInfo:nil] raise];
    return nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_isMonitoring)
    {
        [self stopMonitoring];
    }
}

#pragma mark - Public API

- (void)startMonitoring
{
	@synchronized(self)
	{
        if (_isMonitoring)
		{
			return;
		}

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
    }
}

- (void)stopMonitoring
{
	@synchronized(self)
	{
        if (!_isMonitoring)
		{
			return;
		}

        FSEventStreamStop(_eventStream);
        FSEventStreamInvalidate(_eventStream);
        FSEventStreamRelease(_eventStream);
        _eventStream = NULL;

        _isMonitoring = NO;
    }
}

- (BOOL)isMonitoring
{
	@synchronized(self)
	{
		return _isMonitoring;
	}
}


#pragma - Private Methods
    
- (void)defaultsDidUpdate:(NSNotification *)notification
{
    __weak ReportDownloadFolderMonitor *weakSelf = self;

	@synchronized(self)
	{
        NSString *reportFolder = [[NSUserDefaults standardUserDefaults] objectForKey:AIUserDefaultsDownloadFolderPathKey];

        if (![_downloadFolder isEqualToString:reportFolder])
        {
            _downloadFolder = reportFolder;
            if (_isMonitoring)
            {
                [weakSelf stopMonitoring];
                [weakSelf startMonitoring];
            }
        }
    }
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