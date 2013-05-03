//
//  Created by Felipe Cypriano on 30/04/13.
//
//


#import "ReportOrganizer.h"
#import "ReportInformation.h"
#import "ReportFolderClassifier.h"


@implementation ReportOrganizer {
    NSString *_downloadFolder;
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
    [_queue addOperationWithBlock:^{
        [weakSelf _organizeFolder:[_downloadFolder copy]];
    }];
}

#pragma mark - Private Methods

- (void)_organizeFolder:(NSString *)folder
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtURL:[[NSURL alloc] initWithString:folder]
                                   includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        error:&error];
    if (error)
    {
        NSLog(@"Couldn't get contents of directory '%@'. Error %@", folder, error);
        return;
    }

    ReportFolderClassifier *folderClassifier = [[ReportFolderClassifier alloc] initWithBasePath:_downloadFolder];
    for (NSURL *path in contents)
    {
        if ([self urlIsDirectory:path]) continue;

        NSString *fileName = [self fileNameForURL:path];
        if ([ReportInformation isFileNameAReport:fileName])
        {
            NSString *destination = [folderClassifier pathForReportFileName:fileName];
            NSLog(@"File %@ will be moved to %@", fileName, destination);
        }
    }

}

- (void)defaultsDidUpdate:(NSNotification *)notification
{
    NSString *reportFolder = [[NSUserDefaults standardUserDefaults] objectForKey:AIUserDefaultsDownloadFolderPathKey];

    if (![_downloadFolder isEqualToString:reportFolder])
    {
        _downloadFolder = reportFolder;
    }
}


#pragma mark - Private Methods

- (BOOL)urlIsDirectory:(NSURL *)url
{
    NSNumber *isDirectory;
    [self value:&isDirectory inURL:url key:NSURLIsDirectoryKey];
    return [isDirectory boolValue];
}

- (NSString *)fileNameForURL:(NSURL *)url
{
    NSString *name;
    [self value:&name inURL:url key:NSURLNameKey];
    return name;
}

- (void)value:(out id *)value inURL:(NSURL *)url key:(NSString *)key
{
    NSError *error;
    [url getResourceValue:value forKey:key error:&error];
    if (error)
    {
        NSLog(@"Error getting %@ from %@: %@", key, url, error);
    }
}

@end