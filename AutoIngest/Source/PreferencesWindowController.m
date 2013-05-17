//
//  PreferencesWindowController.m
//  MyAppSales
//
//  Created by Oliver Drobnik on 4/14/13.
//
//

#import "PreferencesWindowController.h"

#import "AccountManager.h"
#import "NSString+AutoIngest.h"


@interface PreferencesWindowController () <NSTokenFieldDelegate>

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
           
            [self validateUsername];
           
            [self addObserver:self forKeyPath:@"username" options:NSKeyValueObservingOptionNew context:nil];
        }
    }
	
    return self;
}

- (void)awakeFromNib
{
	// set version
	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	
	NSString *marketingVersion = infoDictionary[@"CFBundleShortVersionString"];
	NSString *buildVersion = infoDictionary[@"CFBundleVersion"];
	
	NSString *version = [NSString stringWithFormat:@"Version %@ (%@)", marketingVersion, buildVersion];
	self.versionLabel.stringValue = version;
	
	// enable update button if we have Sparkle
	[self.updateButton setEnabled:self.sparkleEnabled];
	
	// add link to iTC Report guide to help text
	
	NSMutableAttributedString *attributedString = [self.reportsHelpText.attributedStringValue mutableCopy];
	NSRange linkRange = [[attributedString string] rangeOfString:@"iTunes Connect Reporting Guide"];
	NSURL *URL = [NSURL URLWithString:@"http://www.apple.com/itunesnews/docs/AppStoreReportingInstructions.pdf"];
	[attributedString addAttribute:NSLinkAttributeName value:URL range:linkRange];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:linkRange];
    [attributedString addAttribute:
	 NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:linkRange];
    [self.reportsHelpText setAllowsEditingTextAttributes: YES];
    [self.reportsHelpText setSelectable: YES];
	self.reportsHelpText.attributedStringValue = attributedString;
	
	// vendor token field
	
	// any non-number is a seperator
	NSMutableCharacterSet *characterSet = [NSMutableCharacterSet alphanumericCharacterSet];
	[characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[characterSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
	
	[characterSet removeCharactersInString:@"1234567890"];
	
	self.vendorTokenField.tokenizingCharacterSet = characterSet;
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


- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"username" context:nil];
    [self removeObserver:self forKeyPath:@"vendorId" context:nil];
}


#pragma mark - KVO


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"username"])
    {
        [self validateUsername];
    }
}

#pragma mark - Validation

- (void)validateUsername
{
    NSString *emailRegEx = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSPredicate *emailPredicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    self.usernameColor = [emailPredicate evaluateWithObject:self.username] ? [NSColor textColor] : [NSColor redColor];
}

#pragma mark - Vendor Token Field

- (NSArray *)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index
{
	NSMutableArray *validTokens = [NSMutableArray array];
	
	for (NSString *oneToken in tokens)
	{
		if ([oneToken isValidVendorIdentifier])
		{
			[validTokens addObject:oneToken];
		}
	}
	
	return validTokens;
}


- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject
{
	// make valid vendor ids "blue pill", everything else plain text
	if ([representedObject isValidVendorIdentifier])
	{
		return NSRoundedTokenStyle;
	}
	
	return NSPlainTextTokenStyle;
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
