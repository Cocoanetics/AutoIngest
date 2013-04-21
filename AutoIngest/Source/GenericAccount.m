//
//  GenericAccount.m
//  ASiST
//
//  Created by Oliver on 09.11.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import "GenericAccount.h"
#import <Security/Security.h>



@interface GenericAccount ()
{
	NSString *_account;
	NSString *_description;
	NSString *_comment;
	NSString *_label;
	NSString *_service;
	NSString *_password;
	
	// the primary key
	NSString *_pk_account;
	NSString *_pk_service;
}

@property(nonatomic, retain) NSString *pk_account;
@property(nonatomic, retain) NSString *pk_service;

@end


@implementation GenericAccount
{
}

#pragma mark Init/dealloc

- (id)initFromKeychainDictionary:(NSDictionary *)dict
{
	if (self = [super init])
	{
		_account = [[dict objectForKey:(id)kSecAttrAccount] copy];
		_description = [[dict objectForKey:(id)kSecAttrDescription] copy];
		_comment = [[dict objectForKey:(id)kSecAttrComment] copy];
		_label = [[dict objectForKey:(id)kSecAttrLabel] copy];
		_service = [[dict objectForKey:(id)kSecAttrService] copy];
		
		// set password only if we have it
		NSData *passwordData = [dict objectForKey:(id)kSecValueData];
		if (passwordData)
		{
			_password = [[NSString alloc] initWithData:passwordData encoding:NSUTF8StringEncoding];
		}
		
		// remember primary key
		self.pk_account = _account?:@"";
		self.pk_service = _service?:@"";
	}
	
	return self;
}


- (id)initService:(NSString *)aService forUser:(NSString *)aUser
{
	if (self = [super init])
	{
		_account = [aUser copy];
		_service = [aService copy];
		
		// remember primary key
		self.pk_account = _account?:@"";
		self.pk_service = _service?:@"";
		
		[self writeToKeychain];
	}
	
	return self;
}


#pragma mark Keychain Access
// search query to find only this account on the keychain
- (NSDictionary *)_uniqueSearchQuery
{
	NSMutableDictionary *query = [NSMutableDictionary dictionary];
	[query setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	[query setObject:_pk_account forKey:(id)kSecAttrAccount];
	[query setObject:_pk_service forKey:(id)kSecAttrService];
	
	// unique means we only want one match
	[query setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
	
	
	return [query copy];
}

- (NSDictionary *)_dictionaryOfCurrentValues
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	dictionary[(id)kSecAttrAccount] = _account?:@"";
	dictionary[(id)kSecAttrService] = _service?:@"";
	
	if (_description)
	{
		dictionary[(id)kSecAttrDescription] = _description;
	}
	
	if (_comment)
	{
		dictionary[(id)kSecAttrComment] = _comment;
	}
	
	if (_label)
	{
		dictionary[(id)kSecAttrLabel] = _label;
	}
	
	NSString *password = _password?:@"";
	NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
	dictionary[(id)kSecValueData] = passwordData;
	
	dictionary[(id)kSecClass] = (id)kSecClassGenericPassword;
	
	return [dictionary copy];
}

- (void)writeToKeychain
{
 	NSDictionary *uniqueSearchQuery = [self _uniqueSearchQuery];
	
	CFDictionaryRef attributes = NULL;
	if (SecItemCopyMatching((__bridge CFDictionaryRef)uniqueSearchQuery, (CFTypeRef *)&attributes) == noErr)
	{
		NSDictionary *updatedValues = [self _dictionaryOfCurrentValues];
 		
		// An implicit assumption is that you can only update a single item at a time.
		OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)(uniqueSearchQuery), (__bridge CFDictionaryRef)(updatedValues));
		
		if (status)
		{
			NSLog(@"Couldn't update the Keychain Item.");
		}
		
		// update primary key
		_pk_account = _account?:@"";
		_pk_service = _service?:@"";
		
		CFRelease(attributes);
	}
	else
	{
		NSDictionary *dictionary = [self _dictionaryOfCurrentValues];
		
		CFDictionaryRef result;
		OSStatus status = SecItemAdd((__bridge CFDictionaryRef)(dictionary), (CFTypeRef *)&result);
		if (status != noErr)
		{
			NSLog(@"Couldn't add the Keychain Item.");
			
			/** -- on Mac
			 CFStringRef message = SecCopyErrorMessageString(status, NULL);
			 NSLog(@"%@", message);
			 CFRelease(message);
			 */
		}
	}
}


- (void)removeFromKeychain
{
	NSDictionary *query = [self _uniqueSearchQuery];
	
	OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
	
	if ( status != noErr && status != errSecItemNotFound)
	{
		NSLog(@"Problem deleting current dictionary.");
	}
}


#pragma mark - Properties

- (void)setAccount:(NSString *)account
{
	if (_account != account)
	{
		_account = [account copy];
		
		[self writeToKeychain];
	}
}

- (void)setPassword:(NSString *)password
{
	// we cannot remove entry from password, only blank it
	if (!password)
	{
		password = @"";
	}
	
	if (_password != password)
	{
		_password = [password copy];
		
		[self writeToKeychain];
	}
}

- (void)setService:(NSString *)service
{
	if (_service != service)
	{
		_service = [service copy];
		
		[self writeToKeychain];
	}
}

- (void)setDescription:(NSString *)description
{
	if (_description != description)
	{
		_description = [description copy];
		
		[self writeToKeychain];
	}
}

- (void)setLabel:(NSString *)newLabel
{
	if (_label != newLabel)
	{
		_label = [newLabel copy];
		
		[self writeToKeychain];
	}
}

- (void)setComment:(NSString *)comment
{
	if (_comment != comment)
	{
		_comment = [comment copy];
		
		[self writeToKeychain];
	}
}

- (NSString *)password
{
	// try to load password if necessary
	if (!_password)
	{
		NSMutableDictionary *query = [[self _uniqueSearchQuery] mutableCopy];
 		
		// we copy the class, service and account as search values
		[query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnAttributes];
		[query setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
		
		CFDictionaryRef attributes = NULL;
		
		if (SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&attributes) == noErr)
		{
			_password = [[NSString alloc] initWithData:[(__bridge NSDictionary *)attributes objectForKey:(id)kSecValueData] encoding:NSUTF8StringEncoding];
		}
		
		CFRelease(attributes);
	}
	
	return _password;
}

@synthesize account = _account;
@synthesize description = _description;
@synthesize comment = _comment;
@synthesize label = _label;
@synthesize password = _password;
@synthesize service = _service;

@end
