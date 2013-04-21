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
#import "AccountManager.h"

#import "StatusItemView.h"

@implementation AppDelegate
{
	NSStatusItem *_statusItem;
	PreferencesWindowController *_preferencesController;
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
    NSString *downloadPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadFolderPath"];
    
    if ([downloadPath hasPrefix:@"~"])
    {
        downloadPath = [downloadPath stringByExpandingTildeInPath];
        
        [[NSUserDefaults standardUserDefaults] setObject:downloadPath forKey:@"DownloadFolderPath"];
    }
}

- (void)awakeFromNib
{
    NSStatusBar *systemStatusBar = [NSStatusBar systemStatusBar];
	_statusItem = [systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    StatusItemView *statusItemView = [[StatusItemView alloc] initWithFrame:CGRectMake(0, 0, systemStatusBar.thickness, systemStatusBar.thickness)];
	statusItemView.statusItem = _statusItem;
    statusItemView.menu = _statusMenu;
    [_statusItem setView:statusItemView];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    DTITCReportManager *reportManager = [DTITCReportManager sharedManager]; // inits it
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidStart:) name:DTITCReportManagerSyncDidStartNotification object:reportManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidFinish:) name:DTITCReportManagerSyncDidFinishNotification object:reportManager];
}

#pragma mark - Actions

- (BOOL)_canSync
{
	NSArray *accounts = [[AccountManager sharedAccountManager] accountsOfType:@"iTunes Connect"];
	
	if (![accounts count])
	{
		return NO;
	}
	
	NSString *vendorID = [[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadVendorID"];
	
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

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(syncNow:))
	{
		return [self _canSync];
	}
	
	return YES;
}

- (void)syncNow:(id)sender
{
    [[DTITCReportManager sharedManager] startSync];
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
	}
	
	[_preferencesController showWindow:sender];
    [_preferencesController.window orderFrontRegardless];
}

#pragma mark - Notifications

- (void)syncDidStart:(NSNotification *)notification
{
    StatusItemView *statusItemView = (StatusItemView *)_statusItem.view;
    statusItemView.isSyncing = YES;
}

- (void)syncDidFinish:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        StatusItemView *statusItemView = (StatusItemView *)_statusItem.view;
        statusItemView.isSyncing = NO;
        
        NSError *error = [notification userInfo][@"Error"];
		 
        NSUserNotification *note = [[NSUserNotification alloc] init];
		 
		 if (error)
		 {
			 [note setTitle:@"Report Syncing Error"];
			 NSString *infoText = [error localizedDescription];
			 [note setInformativeText:infoText];
		 }
		 else
		 {
			 [note setTitle:@"AutoIngest"];
			 NSString *infoText = [NSString stringWithFormat:@"Report download complete"];
			 [note setInformativeText:infoText];
		 }
       
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center deliverNotification:note];
    });
}


@end
