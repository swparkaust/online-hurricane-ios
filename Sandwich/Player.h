//
//  Player.h
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2/23/15.
//  Copyright (c) 2015 Ryuhyun Factory. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Player : NSObject {
    NSString * _playerId;
    NSString * _alias;
    NSMutableArray *_deck;
    int _score;
}

@property (retain) NSString *playerId;
@property (retain) NSString *alias;
@property (retain) NSMutableArray *deck;
@property (assign) int score;

- (id)initWithPlayerId:(NSString*)playerId alias:(NSString*)alias deck:(NSMutableArray *)deck score:(int)score;

@end
