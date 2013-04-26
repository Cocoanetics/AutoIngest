//
//  StatusItemView.m
//  AutoIngest
//
//  Created by Rico Becker on 4/21/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "StatusItemView.h"
#import <QuartzCore/QuartzCore.h>

NSString * const AIMenuWillOpenNotification = @"AIMenuWillOpenNotification";

@interface StatusItemView ()<NSMenuDelegate>

@property (nonatomic, strong) NSImage *image;
@property (nonatomic) BOOL isMenuVisible;

@end


@implementation StatusItemView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.image = [NSImage imageNamed:@"MenuItem"];
        self.wantsLayer = YES;
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (_isMenuVisible)
	{
        [NSColor.selectedMenuItemColor set];
        NSRectFill(dirtyRect);
		self.image = [NSImage imageNamed:@"MenuItemAlt"];
    }
	else
	{
        self.image = [NSImage imageNamed:@"MenuItem"];
	}
	
	[self.image drawAtPoint:NSMakePoint(5, 2) fromRect:NSMakeRect(0, 0, 20, 19) operation:NSCompositeSourceOver fraction:1.0];
}

- (void)mouseDown:(NSEvent *)event
{
	[self openMenu];
}

- (void)openMenu
{
	[self.menu setDelegate:self];
    [self.statusItem popUpStatusItemMenu:self.menu];
    [self setNeedsDisplay:YES];
}

- (void)menuWillOpen:(NSMenu *)menu
{
	[[NSNotificationCenter defaultCenter] postNotificationName:AIMenuWillOpenNotification object:self];
	
	self.isMenuVisible = YES;
    [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu
{
    [menu setDelegate:nil];
	self.isMenuVisible = NO;
    [self setNeedsDisplay:YES];
}

- (void)setIsSyncing:(BOOL)isSyncing
{
	if (_isSyncing != isSyncing)
	{
		_isSyncing = isSyncing;
		
		if (!_isSyncing)
		{
			[self.layer removeAnimationForKey:@"syncAnimation"];
		}
		else
		{
			CABasicAnimation *syncAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
			syncAnimation.duration = .5f;
			syncAnimation.repeatCount = INFINITY;
			syncAnimation.autoreverses = YES;
			syncAnimation.fromValue = @1;
			syncAnimation.toValue = @.33;
			[self.layer addAnimation:syncAnimation forKey:@"syncAnimation"];
		}
	}
}

@end
