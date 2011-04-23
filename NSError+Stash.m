//
//  NSError+Passive.m
//  Progress
//
//  Created by Brian King on 4/23/11.
//  Copyright 2011 King Software Design. All rights reserved.
//

#import "NSError+Stash.h"


@interface NSThread (StashError)
@property (nonatomic, retain) NSMutableArray *errors;
@end

@implementation NSThread (StashError)

- (void) setErrors:(NSMutableArray *)errors {
    NSMutableDictionary *threadDict = [self threadDictionary];
    if (errors) {
        [threadDict setObject:errors forKey:@"BKPassiveErrorArray"];
    } else {
        [threadDict removeObjectForKey:@"BKPassiveErrorArray"];
    }
}
- (NSMutableArray*) errors {
    NSMutableDictionary *threadDict = [self threadDictionary];
    NSMutableArray *errors = [threadDict objectForKey:@"BKPassiveErrorArray"];
    return errors;
}

@end

static id __errorStashDelegate = nil;
static SEL __errorStashSelector = nil;
static BOOL __errorTriggerOncePerRunloop = YES;

@implementation NSError (Stash)
+ (void) setDelegate:(id) delegate {
    __errorStashDelegate = delegate;
}
+ (void) setDelegateSelector:(SEL) selector {
    __errorStashSelector = selector;
}

+ (void) delegateError {
    [__errorStashDelegate performSelector:__errorStashSelector withObject:[self errorFromStash]];
}

+ (void) setTriggerDelegateOncePerRunLoopOnMainThread:(BOOL)triggerOnce {
    __errorTriggerOncePerRunloop = triggerOnce;
}

+ (void) stashError:(NSError*)error {
    if (error == nil) return;
    
    NSMutableArray *errors = [[NSThread currentThread] errors];
    if (!errors) {
        errors = [NSMutableArray array];
        [[NSThread currentThread] setErrors:errors];
    }
    [error logError];
    [errors addObject:error];
    
    if (__errorStashDelegate && __errorStashSelector) {
        if (__errorTriggerOncePerRunloop) {
            // Trigger delegate once per run loop cycle, not immediately.  When it rains it often pours.
            [[NSRunLoop mainRunLoop] cancelPerformSelector:@selector(delegateError) target:self argument:nil];
            [[NSRunLoop mainRunLoop] performSelector:@selector(delegateError) target:self argument:nil order:1000 modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
        } else {
            [self delegateError];
        }
    }    
}

+ (NSError*) errorFromStash {
    NSArray *errors = [[NSThread currentThread] errors];

    if (errors) {
        [NSThread currentThread].errors = nil;

        if ([errors count] > 1) {
            // I don't have much opinion on Domain / code.  
            // Otherwise, I tried to re-use what Core Data does in Multiple Error reporting scenarios.
            // Re-using the domain didn't seem to make sense.
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errors forKey:NSDetailedErrorsKey];
            NSError *detailedError = [NSError errorWithDomain:@"PassiveError" code:NSValidationMultipleErrorsError userInfo:userInfo];
            return detailedError;
        } else {
            return [errors objectAtIndex:0];
        }
    } else {
        return nil;
    }
}

- (void) logError {
    NSDictionary *userInfo = [self userInfo];
    for (NSArray *detailedError in [userInfo allValues])
    {
        if ([detailedError isKindOfClass:[NSArray class]])
        {
            for (NSError *e in detailedError)
            {
                if ([e respondsToSelector:@selector(userInfo)])
                {
                    ARLog(@"Error Details: %@", [e userInfo]);
                }
                else
                {
                    ARLog(@"Error Details: %@", e);
                }
            }
        }
        else
        {
            ARLog(@"Error: %@", detailedError);
        }
    }
    ARLog(@"Error Domain: %@", [self domain]);
    ARLog(@"Recovery Suggestion: %@", [self localizedRecoverySuggestion]);	
}

@end
