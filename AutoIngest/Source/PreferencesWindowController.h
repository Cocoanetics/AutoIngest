//
//  PreferencesWindowController.h
//  MyAppSales
//
//  Created by Oliver Drobnik on 4/14/13.
//
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController

@property (nonatomic, strong) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (weak) IBOutlet NSTextField *versionLabel;
@property (weak) IBOutlet NSButton *updateButton;

@property (nonatomic, assign) BOOL sparkleEnabled;

@end
