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
	_statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[_statusItem setMenu:_statusMenu];
	[_statusItem setTitle:@"AutoIngest"];
	
	[_statusItem setHighlightMode:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    DTITCReportManager *reportManager = [DTITCReportManager sharedManager]; // inits it
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidStart:) name:DTITCReportManagerSyncDidStartNotification object:reportManager];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncDidFinish:) name:DTITCReportManagerSyncDidFinishNotification object:reportManager];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DownloadAutoSync"])
	{
		[reportManager startAutoSyncTimer];
	}
}

#pragma mark - Actions

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if (menuItem.action == @selector(syncNow:))
	{
		return [[DTITCReportManager sharedManager] canSync];
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
    [_statusItem setTitle:@"Syncing"];
}

- (void)syncDidFinish:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_statusItem setTitle:@"AutoIngest"];

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
			 
			 [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"DownloadLastSuccessfulSync"];
		 }
       
        NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
        [center deliverNotification:note];
    });
}


@end
