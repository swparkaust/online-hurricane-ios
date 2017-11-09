//
//  Match.h
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 2/23/15.
//  Copyright (c) 2015 Ryuhyun Factory. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    MatchStateActive = 0,
    MatchStateGameOver
} MatchState;

@interface Match : NSObject {
    MatchState _state;
    NSArray * _players;
}

@property  MatchState state;
@property (retain) NSArray *players;

- (id)initWithState:(MatchState)state players:(NSArray*)players;

@end
