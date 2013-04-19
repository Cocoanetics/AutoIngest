//
//  AccountManager.m
//  ASiST
//
//  Created by Oliver on 07.09.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "AccountManager.h"
#import <Security/Security.h>
#import "GenericAccount.h"

@interface AccountManager ()

- (void) loadAllGenericAccounts;

@end





@implementation AccountManager

@synthesize accounts;

static const UInt8 kKeychainIdentifier[]    = "com.drobnik.asist.KeychainUI\0";


static AccountManager *_sharedInstance = nil;


+ (AccountManager *) sharedAccountManager
{
	if (!_sharedInstance)
	{
		_sharedInstance = [[AccountManager alloc] init];
	}
	
	return _sharedInstance;
}

- (id) init
{
	if (self = [super init])
	{
		[self loadAllGenericAccounts];
		
		// migrate old version primary account
		
		if ([accounts count]==1)
		{
			GenericAccount *singleAccount = [accounts objectAtIndex:0];
			if ([singleAccount.service isEqualToString:@"HomeDir"])
			{
				NSLog(@"Migrating old account %@ to new ITC Service", singleAccount.account);

				/*
				GenericAccount *newAccount = [[GenericAccount alloc] initWithService:@"iTunes Connect" user:singleAccount.account];
				newAccount.description = singleAccount.description;
				newAccount.label = singleAccount.label;
				newAccount.comment = singleAccount.account;
				newAccount.password = singleAccount.password;
				 */
				
				singleAccount.service = @"iTunes Connect";
				singleAccount.description = singleAccount.account;
			}
		}
	}
	
	return self;
}

// this loads all generic accounts from the keychain
- (void) loadAllGenericAccounts
{
	accounts = [[NSMutableArray alloc] init];
	
	NSMutableDictionary *genericPasswordQuery;    // A placeholder for a generic Keychain Item query.
	genericPasswordQuery = [NSMutableDictionary dictionary];
	[genericPasswordQuery setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	NSData *keychainType = [NSData dataWithBytes:kKeychainIdentifier length:strlen((const char *)kKeychainIdentifier)];
	[genericPasswordQuery setObject:keychainType forKey:(id)kSecAttrGeneric];
	
	// We want all generic accounts and all attributes
	[genericPasswordQuery setObject:(id)kSecMatchLimitAll forKey:(id)kSecMatchLimit];
	[genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
	[genericPasswordQuery setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];  // so password is also returned

	
	NSDictionary *tempQuery = [NSDictionary dictionaryWithDictionary:genericPasswordQuery];
	
	CFTypeRef result = nil;
	
	if (SecItemCopyMatching((__bridge CFDictionaryRef)tempQuery, &result) == noErr)
	{
        id myResult = (__bridge id)result; // can be array or dictionary
        
		if ([myResult isKindOfClass:[NSDictionary class]])
		{
			GenericAccount *tmpAcct = [[GenericAccount alloc] initFromKeychainDictionary:myResult];
			[accounts addObject:tmpAcct];
		}
		else if ([myResult isKindOfClass:[NSArray class]])
		{
			for (NSDictionary *oneAccount in myResult)
			{
				GenericAccount *tmpAcct = [[GenericAccount alloc] initFromKeychainDictionary:oneAccount];
				[accounts addObject:tmpAcct];
			}
		}
	}
}

#pragma mark Adding/Removing Accounts

- (GenericAccount *) addAccountForService:(NSString*)aService user:(NSString *)aUser
{
	GenericAccount *tmpAccount = [[GenericAccount alloc] initService:aService forUser:aUser];
	
	[accounts addObject:tmpAccount];
	
	return tmpAccount;
}

- (void) removeAccount:(GenericAccount *)accountToRemove
{
	[accountToRemove removeFromKeychain];
	[self.accounts removeObject:accountToRemove];
}

#pragma mark Retrieving Accounts
- (NSArray *)accountsOfType:(NSString *)type
{
	NSMutableArray *tmpArray = [NSMutableArray array];
	
	for (GenericAccount *oneAccount in accounts)
	{
		if ([oneAccount.service isEqualToString:type])
		{
			[tmpArray addObject:oneAccount];
		}
	}
	
	if ([tmpArray count])
	{
		return [NSArray arrayWithArray:tmpArray];
	}
	else
	{
		return nil;
	}

}

@end
