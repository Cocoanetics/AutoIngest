//
//  StatusItemController.m
//  AutoIngest
//
//  Created by Rico Becker on 4/21/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "StatusItemController.h"

NSString * const AIMenuWillOpenNotification = @"AIMenuWillOpenNotification";

@interface StatusItemController () <NSMenuDelegate>

@property (nonatomic) BOOL isMenuVisible;

@end


@implementation StatusItemController
{
	int _currentFrame;
	NSTimer *_animationTimer;
	BOOL _animationIsStopping;
}

#pragma mark -
#pragma mark Object livecycle

- (id)initWithStatusItem:(NSStatusItem *)statusItem menu:(NSMenu *)menu;
{
	self = [super init];
	
	if (self != nil) {
		_currentFrame = 0;

		NSImage *image = [self imageForFrameNumber:_currentFrame];

		_statusItem = statusItem;
		_statusItem.image = image;
        _statusItem.highlightMode = YES;

		self.menu = menu;

		//[self startAnimating];
	}
	
	return self;
}

#pragma mark -
#pragma mark Events

- (void)menuWillOpen:(NSMenu *)menu
{
	[self stopAnimatingImmediately];

	[[NSNotificationCenter defaultCenter] postNotificationName:AIMenuWillOpenNotification object:self];
	
	self.isMenuVisible = YES;
}

- (void)menuDidClose:(NSMenu *)menu
{
	if (_isSyncing)
	{
		[self startAnimating];
	}
	
	self.isMenuVisible = NO;
}

- (void)setIsSyncing:(BOOL)isSyncing
{
	if (_isSyncing != isSyncing)
	{
		_isSyncing = isSyncing;
		
		if (!_isSyncing)
		{
			[self stopAnimating];
		}
		else
		{
			[self startAnimating];
		}
	}
}

#pragma mark - Animation

- (void)startAnimating
{
	_currentFrame = 0;
	_animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(updateImage:) userInfo:nil repeats:YES];
	
	_animationIsStopping = NO;
}

- (void)stopAnimating
{
	// Animation stops the next time frame 0 comes around.
	_animationIsStopping = YES;
}

- (void)resetAnimation
{
	if (_animationIsStopping)
	{
		[_animationTimer invalidate];
	}
	
	_currentFrame = 0;
	
	[self safelySetImageForCurrentFrame];
}

- (void)stopAnimatingImmediately
{
	[self stopAnimating];
	[self resetAnimation];
}

- (void)updateImage:(NSTimer *)timer
{
#define LAST_FRAME_NUMBER	86
	
	_currentFrame++;
	
	if (_currentFrame > LAST_FRAME_NUMBER)
	{
		[self resetAnimation];
	}
	else
	{
		[self safelySetImageForCurrentFrame];
	}
}

- (NSImage *)imageForFrameNumber:(int)frameNumber
{
	NSString *name = [NSString stringWithFormat:@"AutoIngest Animation %02d Template.pdf", (int)frameNumber]; // Apple recommends to include the filename extension. 
	NSImage *image = [NSImage imageNamed:name];
	
	return image;
}

- (void)safelySetImageForCurrentFrame
{
    NSImage *image = [self imageForFrameNumber:_currentFrame];
	
	if (image != nil)
	{
		_statusItem.image = image;
	}
}

#pragma mark -
#pragma mark Properties

- (void)setMenu:(NSMenu *)menu
{
    if (_menu != menu) {
		[_menu setDelegate:nil];
		
        _menu = menu;
		
		[_statusItem setMenu:_menu];
		[_menu setDelegate:self];
    }
}

@end
