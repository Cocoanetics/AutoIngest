//
//  StatusItemController.h
//  AutoIngest
//
//  Created by Rico Becker on 4/21/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

extern NSString * const AIMenuWillOpenNotification;

@interface StatusItemController : NSObject

@property (nonatomic, readwrite, strong) NSMenu *menu;

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic) BOOL isSyncing;

- (id)initWithStatusItem:(NSStatusItem *)statusItem menu:(NSMenu *)menu;

@end
