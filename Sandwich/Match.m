//
//  Match.m
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2/23/15.
//  Copyright (c) 2015 Ryuhyun Factory. All rights reserved.
//

#import "Match.h"

@implementation Match
@synthesize state = _state;
@synthesize players = _players;

- (id)initWithState:(MatchState)state players:(NSArray *)players
{
    if ((self = [super init])) {
        _state = state;
        _players = players;
    }
    return self;
}

- (void)dealloc
{
    _players = nil;
}

@end
