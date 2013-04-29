//
//  PreferencesWindowController.m
//  MyAppSales
//
//  Created by Oliver Drobnik on 4/14/13.
//
//

#import "PreferencesWindowController.h"

#import "AccountManager.h"


@interface PreferencesWindowController ()

@property (nonatomic, strong) GenericAccount *account;

@end


@implementation PreferencesWindowController
{
    
    GenericAccount *_account;
    
    NSString *_username;
    NSString *_password;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self)
    {
        NSArray *accounts = [[AccountManager sharedAccountManager] accountsOfType:@"iTunes Connect"];
        
        if ([accounts count])
        {
            // initially only one account is supported
            _account = accounts[0];
            self.vendorId = [[NSUserDefaults standardUserDefaults] valueForKey:@"DownloadVendorID"];
            
            [self validateUsername];
            [self validateVendorId];
            
            [self addObserver:self forKeyPath:@"username" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self forKeyPath:@"vendorId" options:NSKeyValueObservingOptionNew context:nil];
        }
    }
	
    return self;
}

- (void)_createAccountIfNecessary
{
    if (_account)
    {
        return; // not necessary
    }
    
    if ([_username length] && [_password length])
    {
        _account = [[AccountManager sharedAccountManager] addAccountForService:@"iTunes Connect" user:_username];
    }
}

#pragma mark - KVO


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"username"])
    {
        [self validateUsername];
    }
    else if ([keyPath isEqualToString:@"vendorId"])
    {
        [self validateVendorId];
        [[NSUserDefaults standardUserDefaults] setValue:self.vendorId forKey:@"DownloadVendorID"];
    }
}


- (void)validateUsername
{
    NSString *emailRegEx = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    self.usernameColor = [emailPredicate evaluateWithObject:self.username] ? [NSColor textColor] : [NSColor redColor];
}


- (void)validateVendorId
{
    NSString *vendorRegEx = @"8\\d{7}";
    NSPredicate *vendorIdPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", vendorRegEx];
    self.vendorIdColor = [vendorIdPredicate evaluateWithObject:self.vendorId] ? [NSColor textColor] : [NSColor redColor];
}


#pragma mark - Actions

- (IBAction)chooseDownloadFolder:(id)sender
{
	NSOpenPanel *openPanel	= [NSOpenPanel openPanel];
	openPanel.canChooseDirectories = YES;
    openPanel.canCreateDirectories = YES;
	openPanel.canChooseFiles = NO;
	openPanel.title = @"Choose Download Folder";
    openPanel.prompt = @"Choose";
    
    // set default path
    NSString *path = [[NSUserDefaults standardUserDefaults] objectForKey:AIUserDefaultsDownloadFolderPathKey];
    NSURL *URL = [NSURL fileURLWithPath:path];
    if (URL)
    {
        [openPanel setDirectoryURL:URL];
    }
    
	[openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        [openPanel close];
        
		if (result == NSFileHandlingPanelOKButton)
		{
            NSString *path = [[openPanel URL] path];
            [[NSUserDefaults standardUserDefaults] setObject:path forKey:AIUserDefaultsDownloadFolderPathKey];
		}
	}];
}

#pragma mark - Properties

- (NSString *)username
{
    return self.account.account;
}

- (void)setUsername:(NSString *)username
{
    _username = username;
    
    [self _createAccountIfNecessary];
    
    _account.account = username;
}

- (NSString *)password
{
    return self.account.password;
}

- (void)setPassword:(NSString *)password
{
    _password = password;
    
    [self _createAccountIfNecessary];
    
    _account.password = password;
}

@synthesize account = _account;

@end
