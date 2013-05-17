//
//  PreferencesWindowController.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 4/14/13.
//
//

@interface PreferencesWindowController : NSWindowController

@property (nonatomic, strong) NSString *username;
@property (nonatomic, copy) NSString *password;

@property (weak) IBOutlet NSTextField *versionLabel;
@property (weak) IBOutlet NSButton *updateButton;
@property (nonatomic, strong) NSColor *usernameColor;
@property (weak) IBOutlet NSTokenField *vendorTokenField;

@property (nonatomic, assign) BOOL sparkleEnabled;

@property (weak) IBOutlet NSTextField *reportsHelpText;

@end
