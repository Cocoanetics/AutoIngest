//
//  PreferencesWindowController.m
//  MyAppSales
//
//  Created by Oliver Drobnik on 4/14/13.
//
//

#import "PreferencesWindowController.h"

@interface PreferencesWindowController ()

@end

@implementation PreferencesWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
	
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)chooseDownloadFolder:(id)sender
{
    NSURL *URL = [NSURL fileURLWithPath: [[NSUserDefaults standardUserDefaults] objectForKey:@"DownloadFolderPath"]];
    
	NSOpenPanel *openPanel	= [NSOpenPanel openPanel];
	openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
	openPanel.canChooseFiles = NO;
	openPanel.title = @"Choose Download Folder";
    openPanel.prompt = @"Choose";
    
    if (URL)
    {
        [openPanel setDirectoryURL:URL];
    }
    
	[openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        [openPanel close];
        
		if (result == NSFileHandlingPanelOKButton)
		{
            NSString *path = [[openPanel URL] path];
            [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"DownloadFolderPath"];
		}
	}];
}

@end
