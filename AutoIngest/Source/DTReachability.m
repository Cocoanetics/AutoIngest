//
//  DTReachability.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 29.04.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTReachability.h"

#import <arpa/inet.h>

@implementation DTReachability


static NSMutableSet *_observers = nil;

static SCNetworkReachabilityRef _reachability = NULL;
static SCNetworkConnectionFlags _connectionFlags = 0;

+ (void)initialize
{
    _observers = [[NSMutableSet alloc] init];
}


+ (id)addReachabilityObserverWithBlock:(void(^)(SCNetworkConnectionFlags connectionFlags))observer
{
    @synchronized(self)
    {
        // copy the block
        DTReachabilityObserverBlock block = [observer copy];
        
        // add it to the observers
        [_observers addObject:block];
        
        
        // first watcher creates reachability
        if (!_reachability)
        {
            BOOL ignoresAdHocWiFi = NO;
            
            struct sockaddr_in ipAddress;
            bzero(&ipAddress, sizeof(ipAddress));
            ipAddress.sin_len = sizeof(ipAddress);
            ipAddress.sin_family = AF_INET;
            ipAddress.sin_addr.s_addr = htonl(ignoresAdHocWiFi ? INADDR_ANY : IN_LINKLOCALNETNUM);
            
            /* Can also create zero addy
             struct sockaddr_in zeroAddress;
             bzero(&zeroAddress, sizeof(zeroAddress));
             zeroAddress.sin_len = sizeof(zeroAddress);
             zeroAddress.sin_family = AF_INET; */
            
            _reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (struct sockaddr *)&ipAddress);
        }
        
        SCNetworkReachabilityContext context = {0, NULL, NULL, NULL, NULL};
        
        if(SCNetworkReachabilitySetCallback(_reachability, ReachabilityCallback, &context))
        {
            if(!SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes))
            {
                NSLog(@"Error: Could not schedule reachability");
                SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
                return nil;
            }
        }
        
        // get the current flags if possible
        if (SCNetworkReachabilityGetFlags(_reachability, &_connectionFlags))
        {
            block(_connectionFlags);
        }
        
        return block;
    }
}

+ (void)removeReachabilityObserver:(id)observer
{
    @synchronized(self)
    {
        [_observers removeObject:observer];
        
        // if this was the last we don't need the reachability no longer
        
        if (![_observers count])
        {
            SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
            
            if (SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetMain(), kCFRunLoopCommonModes))
            {
                NSLog(@"Unscheduled reachability");
            }
            else
            {
                NSLog(@"Error: Could not unschedule reachability");
            }
            
            _reachability = nil;
        }
    }
}

#pragma mark - Internals

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkConnectionFlags flags, void* info)
{
    @autoreleasepool
    {
        for (DTReachabilityObserverBlock observer in _observers)
        {
            observer(flags);
        }
    }
}

@end
