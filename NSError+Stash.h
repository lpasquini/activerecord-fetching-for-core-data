//
//  NSError+Passive.h
//  Progress
//
//  Created by Brian King on 4/23/11.
//  Copyright 2011 King Software Design. All rights reserved.
//
//  API for passive/out-of-band processing of NSErrors easily.

#import <Foundation/Foundation.h>


@interface NSError (Stash)

+ (void) stashError:(NSError*)error;
+ (NSError*) errorFromStash;

- (void) logError;

@end
