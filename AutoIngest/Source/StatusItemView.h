//
//  StatusItemView.h
//  AutoIngest
//
//  Created by Rico Becker on 4/21/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StatusItemView : NSView

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic) BOOL isSyncing;

@end
