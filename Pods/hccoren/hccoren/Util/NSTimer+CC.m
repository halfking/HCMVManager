//
//  NSTimer+CC.m
//  
//
//  Created by Michael Du on 13-5-17.
//  Copyright (c) 2013年 MichaelDu. All rights reserved.
//

#import "NSTimer+CC.h"

NSString *kIsPausedKey				= @"BS IsPaused Key";
NSString *kRemainingTimeIntervalKey	= @"BS RemainingTimeInterval Key";

@interface NSTimer (Private)

- (NSMutableDictionary *)pauseDictionary;

@end

@implementation NSTimer (Private)

- (NSMutableDictionary *)pauseDictionary{
    
	// Create a global dictionary for all instances
	static NSMutableDictionary *globalDictionary = nil;
	if (!globalDictionary) {
		globalDictionary = [[NSMutableDictionary alloc] init];
    }
	
	// Create a local dictionary for this instance
    NSNumber *localDictionaryKey = [NSNumber numberWithInt:(int)self];
    NSMutableDictionary *localDictionary = [globalDictionary objectForKey:localDictionaryKey];
	if (!localDictionary) {
        localDictionary = [NSMutableDictionary dictionary];
		[globalDictionary setObject:localDictionary forKey:localDictionaryKey];
	}
	
	// Return the local dictionary
	return localDictionary;
}

@end

@implementation NSTimer (CC)

- (void)pause
{
	// Prevent invalid timers from being paused
	if (![self isValid]) {
		return;
    }
    NSMutableDictionary *pauseDictionary = [self pauseDictionary];
	
	// Prevent paused timers from being paused again
	NSNumber *isPausedNumber = [pauseDictionary objectForKey:kIsPausedKey];
	if(isPausedNumber && YES == [isPausedNumber boolValue]){
		return;
    }
	
	// Calculate remaining time interval
	NSDate *now		= [NSDate date];
	NSDate *then	= [self fireDate];
	NSTimeInterval remainingTimeInterval = [then timeIntervalSinceDate:now];
	NSNumber *remainingTimeNumber = [NSNumber numberWithDouble:remainingTimeInterval];
	
	// Store remaining time interval
	[pauseDictionary setObject:remainingTimeNumber forKey:kRemainingTimeIntervalKey];
	
	// Pause timer
	[self setFireDate:[NSDate distantFuture]];
	[pauseDictionary setObject:@YES forKey:kIsPausedKey];
}

- (void)resume
{
	// Prevent invalid timers from being resumed
	if(![self isValid]){
		return;
    }
    NSMutableDictionary *pauseDictionary = [self pauseDictionary];
	
	// Prevent paused timers from being paused again
	NSNumber *isPausedNumber = [pauseDictionary objectForKey:kIsPausedKey];
	if(!isPausedNumber || NO == [isPausedNumber boolValue]){
		return;
    }
	
	// Load remaining time interval
	NSNumber *remainingTimeNumber = [pauseDictionary objectForKey:kRemainingTimeIntervalKey];
	NSTimeInterval remainingTimeInterval = [remainingTimeNumber doubleValue];
	
	// Calculate new fire date
	NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:remainingTimeInterval];
	
	// Resume timer
	[self setFireDate:fireDate];
	[pauseDictionary setObject:@NO forKey:kIsPausedKey];
}

@end
