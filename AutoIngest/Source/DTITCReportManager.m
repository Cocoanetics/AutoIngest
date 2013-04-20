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
@end

@implementation DTITCReportManager
{
	BOOL _synching;
	
	NSString *_reportFolder;
	NSString *_vendorID;
	
	NSOperationQueue *_queue;
	
	NSError *_error;
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
	op.delegate = self;
	
	[_queue addOperation:op];
}


- (void)startSync
{
	if (_synching)
	{
		NSLog(@"Already Synching");
		return;
	}
	
	// reset error status
	_error = nil;
	
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
		
		NSDictionary *userInfo = nil;
		
		if (_error)
		{
			userInfo = @{@"Error": _error};
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:DTITCReportManagerSyncDidFinishNotification object:weakself userInfo:userInfo];
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
}

#pragma mark - DTITCReportDownloadOperation Delegate

- (void)operation:(DTITCReportDownloadOperation *)operation didFailWithError:(NSError *)error
{
	_error = error;
	
	[self stopSync];
}


@end
