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
@property (nonatomic, copy) NSString *vendorId;

@property (nonatomic, strong) NSColor *usernameColor;
@property (nonatomic, strong) NSColor *vendorIdColor;

@end
