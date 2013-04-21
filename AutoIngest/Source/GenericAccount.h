//
//  GenericAccount.h
//  ASiST
//
//  Created by Oliver on 09.11.09.
//  Copyright 2009 Drobnik.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GenericAccount : NSObject 

- (id)initFromKeychainDictionary:(NSDictionary *)dict;  // loads existing
- (id)initService:(NSString *)aService forUser:(NSString *)aUser; // creates new one
- (void)removeFromKeychain;


@property (nonatomic, copy) NSString *account;
@property (nonatomic, copy) NSString *description;
@property (nonatomic, copy) NSString *comment;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *service;
@property (nonatomic, copy) NSString *password;

@end
