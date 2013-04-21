//
//  DTITCReportManager.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 19.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTITCReportManager.h"
#import "DTITCReportDownloadOperation.h"

#import "AccountManager.h"

static DTITCReportManager *_sharedInstance = nil;

NSString * const DTITCReportManagerSyncDidStartNotification = @"DTITCReportManagerSyncDidStartNotification";
NSString * const DTITCReportManagerSyncDidFinishNotification = @"DTITCReportManagerSyncDidFinishNotification";


@interface DTITCReportManager () <DTITCReportDownloadOperationDelegate>

@property (strong) NSError *error;

@end

@implementation DTITCReportManager
{
	BOOL _synching;
	
	NSString *_reportFolder;
	NSString *_vendorID;
	
	NSOperationQueue *_queue;
	
	NSTimer *_autoSyncTimer;
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
	DTITCReportDownloadOperation *op = [[DTITCReportDownloadOperation alloc] initForReportsOfType:reportType subType:reportSubType dateType:reportDateType fromAccount:account vendorID:_vendorID intoFolder:_reportFolder];
	op.uncompressFiles = [[NSUserDefaults standardUserDefaults] boolForKey:@"UncompressReports"];
	op.delegate = self;
	
	[_queue addOperation:op];
}

- (void)_reportCompletionWithError:(NSError *)error
{
	NSDictionary *userInfo = nil;
	
	if (error)
	{
		userInfo = @{@"Error": _error};
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTITCReportManagerSyncDidFinishNotification object:self userInfo:userInfo];
}

- (void)startSync
{
	if (_synching)
	{
		NSLog(@"Already Synching");
		return;
	}
	
	if (![self canSync])
	{
		NSLog(@"Cannot start sync because some setup is missing");
		return;
	}
	
	// reset error status
	self.error = nil;
	
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
	
	if (![_vendorID integerValue] || (![_vendorID hasPrefix:@"8"] || [_vendorID length]!=8))
	{
		NSLog(@"Invalid Vendor ID, must be numeric and begin with an 8 and be 8 digits");
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
	
	NSLog(@"Starting Sync");
	
	_synching = YES;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTITCReportManagerSyncDidStartNotification object:weakself];
	
	// completion
	[_queue addOperationWithBlock:^{
		[weakself stopSync];
		
		[weakself _reportCompletionWithError:_error];
	}];
}

- (void)stopSync
{
	if (!_synching)
	{
		return;
	}
	
	NSLog(@"Stopped Sync");
	
	[_queue setSuspended:YES];
	
	// cancel only download operations
	for (NSOperation *op in [_queue operations])
	{
		if ([op isKindOfClass:[DTITCReportDownloadOperation class]])
		{
			[op cancel];
		}
	}
	
	// now the completion block should follow
	[_queue setSuspended:NO];

	
	_synching = NO;
}

- (BOOL)canSync
{
	NSArray *accounts = [[AccountManager sharedAccountManager] accountsOfType:@"iTunes Connect"];
	
	if (![accounts count])
	{
		return NO;
	}
	
	NSString *vendorID = [[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadVendorID"];
	
	// vendor ID must be only digits
	if ([[vendorID stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]] length])
	{
		return NO;
	}
	
	if (![vendorID integerValue] || (![vendorID hasPrefix:@"8"] || [vendorID length]!=8))
	{
		return NO;
	}
	
	NSString *reportFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadFolderPath"];
	BOOL isDirectory = NO;
	if ([[NSFileManager defaultManager] fileExistsAtPath:reportFolder isDirectory:&isDirectory])
	{
		if (!isDirectory)
		{
			return NO;
		}
	}
	else
	{
		return NO;
	}
	
	return YES;
}

#pragma mark - Auto Sync
- (void)startAutoSyncTimer
{
	[_autoSyncTimer invalidate];
	
	_autoSyncTimer = [NSTimer scheduledTimerWithTimeInterval:24*60*60 target:self selector:@selector(_autoSyncTimer:) userInfo:nil repeats:YES];
	
	NSLog(@"AutoSync Timer enabled");
}

- (void)stopAutoSyncTimer
{
	[_autoSyncTimer invalidate];
	_autoSyncTimer = nil;
	
	NSLog(@"AutoSync Timer disabled");
}

- (void)_autoSyncTimer:(NSTimer *)timer
{
	[self startSync];
}

#pragma mark - Notifications

- (void)defaultsDidUpdate:(NSNotification *)notification
{
	
	BOOL needsToStopSync = NO;
	
	NSString *reportFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadFolderPath"];
	NSString *vendorID = [[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadVendorID"];
   
	if (![_reportFolder isEqualToString:reportFolder])
	{
		NSLog(@"Report Download Folder changed to %@", reportFolder);
		_reportFolder = reportFolder;
		
		needsToStopSync = YES;
	}
	
	if (![_vendorID isEqualToString:vendorID])
	{
		NSLog(@"Vendor ID changed to %@", vendorID);
		_vendorID = vendorID;
		
		needsToStopSync = YES;
	}
	
	// need to stop sync, folder changed
	if (_synching && needsToStopSync)
	{
		[self stopSync];
	}
	
	BOOL needsAutoSync = [[NSUserDefaults standardUserDefaults] boolForKey:@"DownloadAutoSync"];
	BOOL hasActiveTimer = (_autoSyncTimer!=nil);
	
	if (needsAutoSync != hasActiveTimer)
	{
		if (needsAutoSync)
		{
			[self startAutoSyncTimer];
		}
		else
		{
			[self stopAutoSyncTimer];
		}
	}
}

#pragma mark - DTITCReportDownloadOperation Delegate

- (void)operation:(DTITCReportDownloadOperation *)operation didFailWithError:(NSError *)error
{
	self.error = error;
	
	[self stopSync];
}


@end
