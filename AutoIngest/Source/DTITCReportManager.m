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
#import "DTReachability.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <arpa/inet.h>

static DTITCReportManager *_sharedInstance = nil;

NSString * const DTITCReportManagerSyncDidStartNotification = @"DTITCReportManagerSyncDidStartNotification";
NSString * const DTITCReportManagerSyncDidFinishNotification = @"DTITCReportManagerSyncDidFinishNotification";


@interface DTITCReportManager () <DTITCReportDownloadOperationDelegate>

@property (strong) NSError *error;

@end

@implementation DTITCReportManager
{	
	NSString *_reportFolder;
	NSString *_vendorID;
	
	NSOperationQueue *_queue;
	
	NSTimer *_autoSyncTimer;
    
    // Reachability
    id _reachabilityObserver;
    SCNetworkConnectionFlags _connectionFlags;
    
    BOOL _waitingForConnectionToSync;
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
        
        // observe if the machine wakes from sleep
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(machineDidWakeUp:) name:NSWorkspaceDidWakeNotification object:nil];
        
        // Reachability
        __weak DTITCReportManager *weakself = self;
        
        _reachabilityObserver = [DTReachability addReachabilityObserverWithBlock:^(SCNetworkConnectionFlags connectionFlags) {
            
            // assign to strong first
            DTITCReportManager *manager = weakself;
            manager->_connectionFlags = connectionFlags;
            
            BOOL hasConnection = [manager _hasInternetConnection];
            
            if (hasConnection)
            {
                NSLog(@"Has Internet Connection");
            }
            else
            {
                NSLog(@"NO Internet Connection");
            }
            
            if (manager->_waitingForConnectionToSync && hasConnection)
            {
                NSLog(@"Internet became available and waiting for that to sync");
                [manager startSync];
            }
        }];
	}
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    
    [DTReachability removeReachabilityObserver:_reachabilityObserver];
}

- (void)_downloadAllReportsOfType:(ITCReportType)reportType subType:(ITCReportSubType)reportSubType dateType:(ITCReportDateType)reportDateType fromAccount:(GenericAccount *)account
{
	DTITCReportDownloadOperation *op = [[DTITCReportDownloadOperation alloc] initForReportsOfType:reportType subType:reportSubType dateType:reportDateType fromAccount:account vendorID:_vendorID intoFolder:_reportFolder];
	op.uncompressFiles = [[NSUserDefaults standardUserDefaults] boolForKey:AIUserDefaultsShouldUncompressReportsKey];
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
    
    NSLog(@"==== Report Synching Completed");
}

- (void)startSync
{
	if (_isSynching)
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
    
    _waitingForConnectionToSync = NO;
	
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
	
	[_queue setSuspended:YES];
	
	if ([defaults boolForKey:@"DownloadDaily"])
	{
		[self _downloadAllReportsOfType:ITCReportTypeSales subType:ITCReportSubTypeSummary dateType:ITCReportDateTypeDaily fromAccount:account];
		
		hasWorkToDo = YES;
	}
	
	if ([defaults boolForKey:@"DownloadWeekly"])
	{
		[self _downloadAllReportsOfType:ITCReportTypeSales subType:ITCReportSubTypeSummary dateType:ITCReportDateTypeWeekly fromAccount:account];
		
		hasWorkToDo = YES;
	}
	
	if ([defaults boolForKey:@"DownloadMonthly"])
	{
		[self _downloadAllReportsOfType:ITCReportTypeSales subType:ITCReportSubTypeSummary dateType:ITCReportDateTypeMonthly fromAccount:account];
		
		hasWorkToDo = YES;
	}
	
	if ([defaults boolForKey:@"DownloadYearly"])
	{
		[self _downloadAllReportsOfType:ITCReportTypeSales subType:ITCReportSubTypeSummary dateType:ITCReportDateTypeYearly fromAccount:account];
		
		hasWorkToDo = YES;
	}
	
	if ([defaults boolForKey:@"DownloadOptInWeekly"])
	{
		[self _downloadAllReportsOfType:ITCReportTypeOptIn subType:ITCReportSubTypeSummary dateType:ITCReportDateTypeWeekly fromAccount:account];
		
		hasWorkToDo = YES;
	}
	
	if ([defaults boolForKey:@"DownloadNewsstandDaily"])
	{
		[self _downloadAllReportsOfType:ITCReportTypeNewsstand subType:ITCReportSubTypeDetailed dateType:ITCReportDateTypeDaily fromAccount:account];
		
		hasWorkToDo = YES;
	}
	
	if ([defaults boolForKey:@"DownloadNewsstandWeekly"])
	{
		[self _downloadAllReportsOfType:ITCReportTypeNewsstand subType:ITCReportSubTypeDetailed dateType:ITCReportDateTypeWeekly fromAccount:account];
		
		hasWorkToDo = YES;
	}
	
	// completion
	[_queue addOperationWithBlock:^{
		[weakself _reportCompletionWithError:_error];
		
		_isSynching = NO;
	}];
	
	if (!hasWorkToDo)
	{
		NSLog(@"Nothing to do for synching!");
		return;
	}
	
	NSLog(@"Starting Sync");
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DTITCReportManagerSyncDidStartNotification object:weakself];
	
	[_queue setSuspended:NO];
	
	_isSynching = YES;
}

- (void)stopSync
{
	if (!_isSynching)
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

	
	_isSynching = NO;
}

- (BOOL)canSync
{
	NSArray *accounts = [[AccountManager sharedAccountManager] accountsOfType:@"iTunes Connect"];
	
	if (![accounts count])
	{
		return NO;
	}
	
	NSString *vendorID = [[NSUserDefaults standardUserDefaults] objectForKey:AIUserDefaultsVendoIDKey];
	
	// vendor ID must be only digits
	if ([[vendorID stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]] length])
	{
		return NO;
	}
	
	if (![vendorID integerValue] || (![vendorID hasPrefix:@"8"] || [vendorID length]!=8))
	{
		return NO;
	}
	
	NSString *reportFolder = [[NSUserDefaults standardUserDefaults] objectForKey:AIUserDefaultsDownloadFolderPathKey];
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
	
	BOOL hasWorkToDo = NO;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults boolForKey:@"DownloadDaily"])
	{
		hasWorkToDo = YES;
	}
	
	if ([defaults boolForKey:@"DownloadWeekly"])
	{
		hasWorkToDo = YES;
	}
	
	if ([defaults boolForKey:@"DownloadMonthly"])
	{
		hasWorkToDo = YES;
	}
	
	if ([defaults boolForKey:@"DownloadYearly"])
	{
		hasWorkToDo = YES;
	}
	
	if (!hasWorkToDo)
	{
		return NO;
	}
	
	return YES;
}

- (BOOL)_hasInternetConnection
{
    BOOL isReachable = ((_connectionFlags & kSCNetworkFlagsReachable) != 0);
    BOOL needsConnection = ((_connectionFlags & kSCNetworkFlagsConnectionRequired) != 0);
    return (isReachable && !needsConnection);
}

#pragma mark - Auto Sync
- (void)startAutoSyncTimer
{
    [_autoSyncTimer invalidate];
    
    // check every hour if the auto-sync criteria is met
    _autoSyncTimer = [NSTimer scheduledTimerWithTimeInterval:60*60 target:self selector:@selector(_startAutoSyncIfNecessary) userInfo:nil repeats:YES];
    
    NSLog(@"AutoSync Timer enabled");

    // do that on next run loop for notifications to have a chance to be received
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _startAutoSyncIfNecessary];
    });
}

- (void)stopAutoSyncTimer
{
	[_autoSyncTimer invalidate];
	_autoSyncTimer = nil;
	
	NSLog(@"AutoSync Timer disabled");
}

// starts synching if there was never a sync or the last successful sync is longer than 24 hours ago
- (void)_startAutoSyncIfNecessary
{
    if (_isSynching)
    {
        return;
    }
    
    NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadLastSuccessfulSync"];

    if (lastSyncDate)
    {
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDate *now =[NSDate date];
        NSDateComponents *lastSyncComps = [gregorian components:NSDayCalendarUnit fromDate:lastSyncDate];
        NSDateComponents *nowComps = [gregorian components:NSDayCalendarUnit fromDate:now];
        NSDateComponents *diffComps = [gregorian components:NSDayCalendarUnit fromDate:lastSyncDate toDate:now options:0];
        
        if (lastSyncComps.day != nowComps.day)
        {
            // different date, only sync if its at least the same hour in day or later
            if (diffComps.day <= 1 && nowComps.hour < lastSyncComps.hour)
            {
                // less than a day
                return;
            }
            
            // either last sync is longer then 1 day or its a later hour in the day than last sync on day before
        }
        else
        {
            // same date, never sync
            return;
        }
    }
    
    if ([self _hasInternetConnection])
    {
        NSLog(@"Last Sync longer than 24 hours ago, starting sync now");
        [self startSync];
    }
    else
    {
        NSLog(@"Last Sync longer than 24 hours ago, but no internet connection, deferring sync");
        _waitingForConnectionToSync = YES;
    }
}

#pragma mark - Notifications

- (void)defaultsDidUpdate:(NSNotification *)notification
{
	
	BOOL needsToStopSync = NO;
	
	NSString *reportFolder = [[NSUserDefaults standardUserDefaults] objectForKey:AIUserDefaultsDownloadFolderPathKey];
	NSString *vendorID = [[NSUserDefaults standardUserDefaults] objectForKey:AIUserDefaultsVendoIDKey];
   
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
	if (_isSynching && needsToStopSync)
	{
		[self stopSync];
	}
	
	BOOL needsAutoSync = [[NSUserDefaults standardUserDefaults] boolForKey:AIUserDefaultsShouldAutoSyncKey];
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

- (void)machineDidWakeUp:(NSNotification *)notification
{
    [self _startAutoSyncIfNecessary];
}

#pragma mark - DTITCReportDownloadOperation Delegate

- (void)operation:(DTITCReportDownloadOperation *)operation didFailWithError:(NSError *)error
{
	self.error = error;
	
	[self stopSync];
}


@end
