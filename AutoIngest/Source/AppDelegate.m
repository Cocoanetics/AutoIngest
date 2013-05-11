//
//  AppDelegate.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 19.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "AppDelegate.h"

#import "PreferencesWindowController.h"
#import "DTITCReportManager.h"

#import "StatusItemController.h"
#import "ReportDownloadFolderMonitor.h"
#import "ReportOrganizer.h"
#import "ReportInformation.h"

#if SPARKLE
#import <Sparkle/Sparkle.h>
#endif

@interface AppDelegate ()

@property (weak) IBOutlet NSMenuItem *syncMenuItem;
@property (weak) IBOutlet NSMenuItem *preferencesMenuItem;
@property (weak) IBOutlet NSMenuItem *quitMenuItem;


@end


@implementation AppDelegate
{
	StatusItemController *_statusItemController;
	PreferencesWindowController *_preferencesController;
	
	// Sparkle
	id _sparkle;
}


+ (void)initialize
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
    NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if (defaults)
    {
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    }
    
    // replace tilde if necessary
    NSString *downloadPath = [[NSUserDefaults standardUserDefaults] objectForKey:AIUserDefaultsDownloadFolderPathKey];
    
    if ([downloadPath hasPrefix:@"~"])
    {
        downloadPath = [downloadPath stringByExpandingTildeInPath];
        
        [[NSUserDefaults standardUserDefaults] setObject:downloadPath forKey:AIUserDefaultsDownloadFolderPathKey];
    }
}

- (void)awakeFromNib
{
    NSStatusBar *systemStatusBar = [NSStatusBar systemStatusBar];
	NSStatusItem *statusItem = [systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    _statusItemController = [[StatusItemController alloc] initWithStatusItem:statusItem menu:_statusMenu];

    _syncMenuItem.title = NSLocalizedString(@"Sync now", nil);
    _preferencesMenuItem.title = NSLocalizedString(@"Preferences...", nil);
    
    NSString *applicationName = [[NSBundle mainBundle] localizedInfoDictionary][@"CFBundleDisplayName"];
    _quitMenuItem.title = [NSString stringWithFormat:NSLocalizedString(@"Quit %@", @"Quit App"), applicationName];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    DTITCReportManager *reportManager = [DTITCReportManager sharedManager]; // inits it
    
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(syncDidStart:) name:DTITCReportManagerSyncDidStartNotification object:reportManager];
    [nc addObserver:self selector:@selector(syncDidFinish:) name:DTITCReportManagerSyncDidFinishNotification object:reportManager];

	[nc addObserver:self selector:@selector(menuWillOpen:) name:AIMenuWillOpenNotification object:nil];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
    if ([defaults boolForKey:AIUserDefaultsShouldAutoOrganizeReportsKey])
    {
		[[ReportOrganizer sharedOrganizer] organizeAllReports];
        [[ReportDownloadFolderMonitor sharedMonitor] startMonitoring];
    }
	
    [nc addObserver:self selector:@selector(startStopDownloadFolderMonitor:) name:NSUserDefaultsDidChangeNotification object:nil];
	
	[self _startSparkleIfAvailable];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    ReportDownloadFolderMonitor *monitor = [ReportDownloadFolderMonitor sharedMonitor];
    if ([monitor isMonitoring])
    {
         [monitor stopMonitoring];
    }
}

#pragma mark - Sparkle

- (void) _startSparkleIfAvailable
{
	if (!NSClassFromString(@"SUUpdater"))
	{
		return;
	}

#if SPARKLE
	_sparkle = [[SUUpdater alloc] init];
	[_sparkle setDelegate:self];
#endif
}


#pragma mark - Actions

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(syncMenuItemAction:))
	{
		return [[DTITCReportManager sharedManager] canSync];
	}
	
	return YES;
}

- (IBAction)syncMenuItemAction:(id)sender
{
    DTITCReportManager *reportManager = [DTITCReportManager sharedManager];
    if (reportManager.isSynching)
    {
        [reportManager stopSync];
    }
    else
    {
		if (![reportManager canSync])
		{
			NSLog(@"Report Manager reports unable to sync");
			return;
		}
		
        [reportManager startSync];
    }    
}


- (void)quitApplication:(id)sender
{
	[NSApp quitApplication:sender];
}

- (void)showPreferences:(id)sender
{
	if (!_preferencesController)
	{
		_preferencesController = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindowController"];
		
		if (_sparkle)
		{
			_preferencesController.sparkleEnabled = YES;
		}
	}
	
	[_preferencesController showWindow:sender];
    [_preferencesController.window orderFrontRegardless];
}

- (void)checkForUpdates:(id)sender
{
	[_sparkle checkForUpdates:sender];
}

#pragma mark - Notifications

- (void)menuWillOpen:(NSNotification *)notification
{
	if (![NSApp isActive])
	{
		[NSApp activateIgnoringOtherApps:YES];
	}
	
	NSWindow *preferencesWindow = _preferencesController.window;
	if (preferencesWindow.isVisible)
	{
		[_preferencesController.window orderFront:self];
	}
}

- (void)syncDidStart:(NSNotification *)notification
{
    _statusItemController.isSyncing = YES;
	
	_syncMenuItem.title = NSLocalizedString(@"Stop sync", nil);
}

- (void)syncDidFinish:(NSNotification *)notification
{
	_syncMenuItem.title = NSLocalizedString(@"Sync now", nil);

	
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _statusItemController.isSyncing = NO;
        _syncMenuItem.title = NSLocalizedString(@"Sync now", nil);
		
		NSDictionary *userInfo = [notification userInfo];

        if ([NSUserNotification class] && [NSUserNotificationCenter class])
        {
            NSError *error = userInfo[@"Error"];

            NSUserNotification *note = [[NSUserNotification alloc] init];

            if (error)
            {
                [note setTitle:@"Report Syncing Error"];
                NSString *infoText = [error localizedDescription];
                [note setInformativeText:infoText];
            }
            else
            {
                [note setTitle:@"Report Synching Complete"];
				
				NSString *infoText = nil;
				
				NSDictionary *statsDict = userInfo[@"Stats"];
				
				if ([statsDict count])
				{
					NSMutableString *tmpString = [NSMutableString stringWithFormat:@""];
					
					NSUInteger index = 0;
					for (ReportInformation *reportInfo in statsDict)
					{
						if (index)
						{
							[tmpString appendString:@", "];
						}
						
						NSNumber *countNum = statsDict[reportInfo];
						
						[tmpString appendFormat:@"%@ %@ %@", countNum, [reportInfo dateTypeStringValue], [reportInfo typeStringValue]];
						
						index++;
					}
					
					infoText = tmpString;
				}
				else
				{
					infoText = @"No Reports Downloaded";
				}
				
				[note setInformativeText:infoText];
				
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:AIUserDefaultsLastSuccessfulSyncDateKey];
            }

            NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
            [center deliverNotification:note];
        }
    });
}

- (void)startStopDownloadFolderMonitor:(NSNotification *)notification
{
    BOOL shouldOrganize = [[NSUserDefaults standardUserDefaults] boolForKey:AIUserDefaultsShouldAutoOrganizeReportsKey];
    ReportDownloadFolderMonitor *monitor = [ReportDownloadFolderMonitor sharedMonitor];
    if (shouldOrganize)
    {
        [[ReportOrganizer sharedOrganizer] organizeAllReports];
        [monitor startMonitoring];
    }
    else if ([monitor isMonitoring])
    {
        [monitor stopMonitoring];
    }
}

#pragma mark - Sparkle Delegate

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	NSLog(@"should terminate");
	return NSTerminateNow;
}

- (void)updaterWillRelaunchApplication:(id)updater
{
	NSLog(@"updater will relaunch");
}

@end
