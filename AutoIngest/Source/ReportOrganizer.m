//
//  Created by Felipe Cypriano on 30/04/13.
//
//


#import "ReportOrganizer.h"


@implementation ReportOrganizer {
    NSString *_downloadFolder;
    BOOL _isOrganizing;
    NSOperationQueue *_queue;
}

+ (ReportOrganizer *)sharedOrganizer
{
    static ReportOrganizer *sharedInstance;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        sharedInstance = [[ReportOrganizer alloc] initPrivate];
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

        _queue = [[NSOperationQueue alloc] init];
        _queue.maxConcurrentOperationCount = 1;
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
    if ([_queue operationCount] > 0)
    {
        [_queue cancelAllOperations];
    }
}


#pragma mark - Public API

- (void)organizeAllReports
{
    if ([_queue operationCount] > 0) return;

    __weak ReportOrganizer *weakSelf = self;
    [_queue addOperationWithBlock:^
    {
        [weakSelf _organizeFolder:[_downloadFolder copy]];
    }];
}

#pragma mark - Private Methods

- (void)_organizeFolder:(NSString *)folder
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:folder error:&error];
    if (error)
    {
        NSLog(@"Couldn't get contents of directory '%@'. Error %@", folder, error);
        return;
    }

    NSLog(@"%@ - contents %@", [NSDate date], contents);
    // TODO do the organization
}

- (void)defaultsDidUpdate:(NSNotification *)notification
{
    NSString *reportFolder = [[NSUserDefaults standardUserDefaults] objectForKey:AIUserDefaultsDownloadFolderPathKey];

    if (![_downloadFolder isEqualToString:reportFolder])
    {
        _downloadFolder = reportFolder;
    }
}


@end