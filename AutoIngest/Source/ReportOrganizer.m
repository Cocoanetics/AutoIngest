//
//  ReportOrganizer.m
//  AutoIngest
//
//  Created by Felipe Cypriano on 30/04/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "ReportOrganizer.h"
#import "ReportInformation.h"
#import "ReportFolderClassifier.h"

@implementation ReportOrganizer
{
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
    if ([_queue operationCount])
	{
		// organizing already going on
		return;
	}

    __weak ReportOrganizer *weakSelf = self;
    [_queue addOperationWithBlock:^{
        [weakSelf _organizeFolder:[_downloadFolder copy]];
    }];
}

#pragma mark - Private Methods

- (void)_organizeFolder:(NSString *)folder
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtURL:[NSURL fileURLWithPath:folder isDirectory:YES]
                                   includingPropertiesForKeys:@[NSURLIsDirectoryKey, NSURLNameKey]
                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                        error:&error];
    if (error)
    {
        NSLog(@"Couldn't get contents of directory '%@'. Error %@", folder, error);
        return;
    }

    ReportFolderClassifier *folderClassifier = [[ReportFolderClassifier alloc] initWithBasePath:folder];
    for (NSURL *path in contents)
    {
        if ([self _urlIsDirectory:path])
		{
			// we don't care about folders
			continue;
		}

        NSString *fileName = [self fileNameForURL:path];
		
        if ([ReportInformation isFileNameAReport:fileName])
        {
            NSString *destination = [folderClassifier pathForReportFileName:fileName];
			
            if (![self _createDirectoryIfNeeded:destination])
			{
				continue;
			}
			
            NSURL *destFile = [[NSURL fileURLWithPath:destination] URLByAppendingPathComponent:fileName];
			
			// move the report into the structure
            if (![fileManager fileExistsAtPath:[destFile path]])
			{
                [self _moveFileAtURL:path toURL:destFile];
			}
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

- (BOOL)_urlIsDirectory:(NSURL *)url
{
    NSNumber *isDirectory;
    [self _value:&isDirectory inURL:url key:NSURLIsDirectoryKey];
	
    return [isDirectory boolValue];
}

- (NSString *)fileNameForURL:(NSURL *)url
{
    NSString *name;
    [self _value:&name inURL:url key:NSURLNameKey];
	
    return name;
}

- (void)_value:(out id *)value inURL:(NSURL *)url key:(NSString *)key
{
    NSError *error;
    [url getResourceValue:value forKey:key error:&error];
	
    if (error)
    {
        NSLog(@"Error getting %@ from %@: %@", key, url, error);
    }
}

- (BOOL)_createDirectoryIfNeeded:(NSString *)directory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL createdOrAlreadyExists = [fileManager fileExistsAtPath:directory];
    if (!createdOrAlreadyExists)
    {
        NSError *createDirError;
        createdOrAlreadyExists = [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&createDirError];
        if (createDirError)
        {
            NSLog(@"Couldn't create directory '%@'. Cause: %@", directory, createDirError);
            createdOrAlreadyExists = NO;
        }
    }
    return createdOrAlreadyExists;
}

- (void)_moveFileAtURL:(NSURL *)file toURL:(NSURL *)destination
{
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:file toURL:destination error:&error];
	
    if (error)
    {
        NSLog(@"Error moving file to %@. Cause: %@", destination, error);
    }
}

@end