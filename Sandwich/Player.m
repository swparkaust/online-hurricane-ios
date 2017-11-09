//
//  Player.m
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2/23/15.
//  Copyright (c) 2015 Ryuhyun Factory. All rights reserved.
//

#import "Player.h"

@implementation Player
@synthesize playerId = _playerId;
@synthesize alias = _alias;
@synthesize deck = _deck;
@synthesize score = _score;

- (id)initWithPlayerId:(NSString *)playerId alias:(NSString *)alias deck:(NSMutableArray *)deck score:(int)score
{
    if ((self = [super init])) {
        _playerId = playerId;
        _alias = alias;
        _deck = deck;
        _score = score;
    }
    return self;
}

- (void)dealloc
{
    _playerId = nil;
    _alias = nil;
    _deck = nil;
}

@end
