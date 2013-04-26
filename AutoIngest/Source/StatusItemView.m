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
{
	NSInteger currentFrame;
	NSTimer *animTimer;
	BOOL _animationIsStopping;
}

- (id)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.image = [NSImage imageNamed:@"AutoIngest_000"];
	}
	
	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	if (_isMenuVisible)
	{
		[NSColor.selectedMenuItemColor set];
		NSRectFill(dirtyRect);
		
		[self.image drawAtPoint:NSMakePoint(5, 2) fromRect:NSMakeRect(0, 0, 20, 19) operation:NSCompositeXOR fraction:1.0];
	}
	else
	{
		[self.image drawAtPoint:NSMakePoint(5, 2) fromRect:NSMakeRect(0, 0, 20, 19) operation:NSCompositeSourceOver fraction:1.0];
	}
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
	currentFrame = 0;
	animTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(updateImage:) userInfo:nil repeats:YES];
	
	_animationIsStopping = NO;
}

- (void)stopAnimating
{
	// animation stops on next time frame 0
	_animationIsStopping = YES;
}

- (void)updateImage:(NSTimer *)timer
{
	currentFrame++;

	if (currentFrame>86)
	{
		if (_animationIsStopping)
		{
			[animTimer invalidate];
		}
		
		currentFrame = 0;
	}

	//get the image for the current frame
	NSString *name = [NSString stringWithFormat:@"AutoIngest_%03d",(int)currentFrame];
	NSImage *image = [NSImage imageNamed:name];
	
	[self setImage:image];
}

#pragma mark - Properties

- (void)setImage:(NSImage *)image
{
	_image = image;
	[self setNeedsDisplay:YES];
}

@end
