//
//  GameKitHelper.m
//  OnlineSandwiches
//
//  Created by Sunwoo Park on 1/4/15.
//  Copyright (c) 2015 Ryuhyun Factory. All rights reserved.
//

#import "NetworkController.h"
#import "MessageWriter.h"
#import "MessageReader.h"
#import "Match.h"
#import "Player.h"
#import "OnlineSandwiches-Swift.h"

@interface NetworkController (PrivateMethods)
- (BOOL)writeChunk;
@end

typedef enum {
    MessagePlayerConnected = 0,
    MessageNotInMatch,
    MessageStartMatch,
    MessageMatchStarted,
    MessageActivatePlayer,
    MessageTurnedCard,
    MessagePlayerTurnedCard,
    MessageDidSlap,
    MessagePlayerClaimedPile,
    MessagePlayerDiscardedCard,
    MessageGameOver,
    MessageRestartMatch,
    MessageNotifyReady,
    MessageQuitMatch,
    MessageChat
} MessageType;

@implementation NetworkController
@synthesize gameCenterAvailable = _gameCenterAvailable;
@synthesize userAuthenticated = _userAuthenticated;
@synthesize state = _state;
@synthesize inputStream = _inputStream;
@synthesize outputStream = _outputStream;
@synthesize inputOpened = _inputOpened;
@synthesize outputOpened = _outputOpened;
@synthesize inputBuffer = _inputBuffer;
@synthesize outputBuffer = _outputBuffer;
@synthesize okToWrite = _okToWrite;
@synthesize presentingViewController = _presentingViewController;
@synthesize mmvc = _mmvc;
@synthesize pendingInvite = _pendingInvite;
@synthesize pendingPlayersToInvite = _pendingPlayersToInvite;
@synthesize leaderboardIdentifier = _leaderboardIdentifier;

#pragma mark - Helpers

static NetworkController *sharedController = nil;
+ (NetworkController *) sharedInstance {
    if (!sharedController) {
        sharedController = [[NetworkController alloc] init];
    }
    return sharedController;
}

- (BOOL)isGameCenterAvailable {
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

- (void)setState:(NetworkState)state {
    _state = state;
    if (_delegate) {
        [_delegate stateChanged:_state];
    }
}

- (void)dismissMatchmaker {
    [_presentingViewController dismissViewControllerAnimated:YES completion:nil];
    self.mmvc = nil;
    self.presentingViewController = nil;
}

#pragma mark - Init

- (id)init {
    if ((self = [super init])) {
        [self setState:_state];
        _gameCenterAvailable = [self isGameCenterAvailable];
        if (_gameCenterAvailable) {
            NSNotificationCenter *nc =
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self
                   selector:@selector(authenticationChanged)
                       name:GKPlayerAuthenticationDidChangeNotificationName
                     object:nil];
        }
        _leaderboardIdentifier = @"";
    }
    return self;
}

#pragma mark - Message sending / receiving

- (void)sendData:(NSData *)data {
    
    if (_outputBuffer == nil) return;
    
    int dataLength = (int)data.length;
    dataLength = htonl(dataLength);
    [_outputBuffer appendBytes:&dataLength length:sizeof(dataLength)];
    [_outputBuffer appendData:data];
    if (_okToWrite) {
        [self writeChunk];
        NSLog(@"Wrote message");
    } else {
        NSLog(@"Queued message");
    }
}

- (void)sendPlayerConnected:(BOOL)continueMatch {
    [self setState:NetworkStatePendingMatchStatus];
    
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessagePlayerConnected];
    [writer writeString:[GKLocalPlayer localPlayer].playerID];
    [writer writeString:[GKLocalPlayer localPlayer].alias];
    [writer writeByte:continueMatch];
    [self sendData:writer.data];
}

- (void)sendStartMatch:(NSArray *)players {
    [self setState:NetworkStatePendingMatchStart];
    
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageStartMatch];
    [writer writeByte:players.count];
    for (NSString *playerId in players) {
        [writer writeString:playerId];
    }
    [self sendData:writer.data];
}

- (void)sendTurnedCard {
    
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageTurnedCard];
    [self sendData:writer.data];
    
}

- (void)sendDidSlap {
    
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageDidSlap];
    [self sendData:writer.data];
    
}

- (void)sendRestartMatch {
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageRestartMatch];
    [self sendData:writer.data];
}

- (void)sendNotifyReady:(NSString *)inviter {
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageNotifyReady];
    [writer writeString:inviter];
    [self sendData:writer.data];
}

- (void)sendQuitMatch {
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageQuitMatch];
    [self sendData:writer.data];
}

- (void)sendChat:(NSString *)text {
    MessageWriter * writer = [[MessageWriter alloc] init];
    [writer writeByte:MessageChat];
    [writer writeString:text];
    [self sendData:writer.data];
}

- (void)processMessage:(NSData *)data {
    MessageReader * reader = [[MessageReader alloc] initWithData:data];
    
    unsigned char msgType = [reader readByte];
    if (msgType == MessageNotInMatch) {
        [self setState:NetworkStateReceivedMatchStatus];
        [_delegate setNotInMatch];
    } else if (msgType == MessageMatchStarted) {
        [self setState:NetworkStateMatchActive];
        [self dismissMatchmaker];
        unsigned char matchState = [reader readByte];
        NSMutableArray * players = [NSMutableArray array];
        unsigned char numPlayers = [reader readByte];
        for (unsigned char i = 0; i < numPlayers; ++i) {
            NSString *playerId = [reader readString];
            NSString *alias = [reader readString];
            NSMutableArray *deck = [NSMutableArray array];
            unsigned char numCards = [reader readByte];
            for (unsigned char i = 0; i < numCards; ++i) {
                int rank = [reader readInt];
                int suit = [reader readInt];
                NSDictionary *card = @{
                                       @"rank" : [NSNumber numberWithInt:rank],
                                       @"suit" : [NSNumber numberWithInt:suit],
                                       };
                [deck addObject:card];
            }
            int score = [reader readInt];
            Player *player = [[Player alloc] initWithPlayerId:playerId alias:alias deck:deck score:score];
            [players addObject:player];
        }
        Match * match = [[Match alloc] initWithState:matchState players:players];
        [_delegate matchStarted:match];
    } else if (msgType == MessageActivatePlayer && _state == NetworkStateMatchActive) {
        unsigned char playerIndex = [reader readByte];
        [_delegate activatePlayer:playerIndex];
    } else if (msgType == MessagePlayerTurnedCard && _state == NetworkStateMatchActive) {
        unsigned char playerIndex = [reader readByte];
        int rank = [reader readInt];
        int suit = [reader readInt];
        int playerScore = [reader readInt];
        [_delegate player:playerIndex turnedCardWithRank:rank suit:suit playerScore:playerScore];
    } else if (msgType == MessagePlayerClaimedPile && _state == NetworkStateMatchActive) {
        unsigned char playerIndex = [reader readByte];
        int playerScore = [reader readInt];
        [_delegate playerClaimedPile:playerIndex playerScore:playerScore];
    } else if (msgType == MessagePlayerDiscardedCard && _state == NetworkStateMatchActive) {
        unsigned char playerIndex = [reader readByte];
        int rank = [reader readInt];
        int suit = [reader readInt];
        int playerScore = [reader readInt];
        [_delegate player:playerIndex discardedCardWithRank:rank suit:suit playerScore:playerScore];
    } else if (msgType == MessageGameOver && _state == NetworkStateMatchActive) {
        unsigned char winnerIndex = [reader readByte];
        int winnerScore = [reader readInt];
        [_delegate gameOver:winnerIndex winnerScore:winnerScore];
    } else if (msgType == MessageNotifyReady) {
        NSString *playerId = [reader readString];
        NSLog(@"Player %@ ready", playerId);
        if (_mmvc != nil) {
            [_mmvc setHostedPlayer:playerId connected:YES];
        }
    } else if (msgType == MessageChat && _state == NetworkStateMatchActive) {
        NSString *text = [reader readString];
        [_delegate chat:text];
    }
}

#pragma mark - Server communication

- (void)connect {
    
    self.inputBuffer = [NSMutableData data];
    self.outputBuffer = [NSMutableData data];
    
    [self setState:NetworkStateConnectingToServer];
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"ec2-54-201-29-128.us-west-2.compute.amazonaws.com", 63520, &readStream, &writeStream);
    _inputStream = (__bridge_transfer NSInputStream *)readStream;
    _outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    [_inputStream setDelegate:self];
    [_outputStream setDelegate:self];
    [_inputStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
    [_outputStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream open];
    [_outputStream open];
}

- (void)disconnect {
    
    [self setState:NetworkStateConnectingToServer];
    
    if (_inputStream != nil) {
        self.inputStream.delegate = nil;
        [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_inputStream close];
        self.inputStream = nil;
        self.inputBuffer = nil;
    }
    if (_outputStream != nil) {
        self.outputStream.delegate = nil;
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream = nil;
        self.outputBuffer = nil;
    }
}

- (void)reconnect {
    [self disconnect];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self connect];
    });
}

- (void)checkForMessages {
    while (true) {
        if (_inputBuffer.length < sizeof(int)) {
            return;
        }
        
        int msgLength = *((int *) _inputBuffer.bytes);
        msgLength = ntohl(msgLength);
        if (_inputBuffer.length < msgLength) {
            return;
        }
        
        NSData * message = [_inputBuffer subdataWithRange:NSMakeRange(4, msgLength)];
        [self processMessage:message];
        
        int amtRemaining = (int)_inputBuffer.length - msgLength - sizeof(int);
        if (amtRemaining == 0) {
            self.inputBuffer = [[NSMutableData alloc] init];
        } else {
            NSLog(@"Creating input buffer of length %lu", (unsigned long)amtRemaining);
            self.inputBuffer = [[NSMutableData alloc] initWithBytes:_inputBuffer.bytes+4+msgLength length:amtRemaining];
        }
        
    }
}

- (void)inputStreamHandleEvent:(NSStreamEvent)eventCode {
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"Opened input stream");
            _inputOpened = YES;
            if (_inputOpened && _outputOpened && _state == NetworkStateConnectingToServer) {
                [self setState:NetworkStateConnected];
                BOOL continueMatch = _pendingInvite == nil;
                [self sendPlayerConnected:continueMatch];
            }
        }
        case NSStreamEventHasBytesAvailable: {
            if ([_inputStream hasBytesAvailable]) {
                NSLog(@"Input stream has bytes...");
                // TODO: Read bytes
                NSInteger       bytesRead;
                uint8_t         buffer[32768];
                
                bytesRead = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                if (bytesRead == -1) {
                    NSLog(@"Network read error");
                } else if (bytesRead == 0) {
                    NSLog(@"No data read, reconnecting");
                    [self reconnect];
                } else {
                    NSLog(@"Read %ld bytes", (long)bytesRead);
                    [_inputBuffer appendData:[NSData dataWithBytes:buffer length:bytesRead]];
                    [self checkForMessages];
                }
            }
        } break;
        case NSStreamEventHasSpaceAvailable: {
            assert(NO); // should never happen for the input stream
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"Stream open error, reconnecting");
            [self reconnect];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (BOOL)writeChunk {
    int amtToWrite = (int)MIN(_outputBuffer.length, 1024);
    if (amtToWrite == 0) return FALSE;
    
    NSLog(@"Amt to write: %lu/%lu", (unsigned long)amtToWrite, (unsigned long)_outputBuffer.length);
    
    int amtWritten = (int)[self.outputStream write:_outputBuffer.bytes maxLength:amtToWrite];
    if (amtWritten < 0) {
        [self reconnect];
    }
    int amtRemaining = (int)_outputBuffer.length - amtWritten;
    if (amtRemaining == 0) {
        self.outputBuffer = [NSMutableData data];
    } else {
        NSLog(@"Creating output buffer of length %lu", (unsigned long)amtRemaining);
        self.outputBuffer = [NSMutableData dataWithBytes:_outputBuffer.bytes+amtWritten length:amtRemaining];
    }
    NSLog(@"Wrote %ld bytes, %lu remaining.", (long)amtWritten, (unsigned long)amtRemaining);
    _okToWrite = FALSE;
    return TRUE;
}

- (void)outputStreamHandleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventOpenCompleted: {
            NSLog(@"Opened output stream");
            _outputOpened = YES;
            if (_inputOpened && _outputOpened && _state == NetworkStateConnectingToServer) {
                [self setState:NetworkStateConnected];
                // TODO: Send message to server
                BOOL continueMatch = _pendingInvite == nil;
                [self sendPlayerConnected:continueMatch];
            }
        } break;
        case NSStreamEventHasBytesAvailable: {
            assert(NO);     // should never happen for the output stream
        } break;
        case NSStreamEventHasSpaceAvailable: {
            NSLog(@"Ok to send");
            // TODO: Write bytes
            BOOL wroteChunk = [self writeChunk];
            if (!wroteChunk) {
                _okToWrite = TRUE;
            }
        } break;
        case NSStreamEventErrorOccurred: {
            NSLog(@"Stream open error, reconnecting");
            [self reconnect];
        } break;
        case NSStreamEventEndEncountered: {
            // ignore
        } break;
        default: {
            assert(NO);
        } break;
    }
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (aStream == _inputStream) {
            [self inputStreamHandleEvent:eventCode];
        } else if (aStream == _outputStream) {
            [self outputStreamHandleEvent:eventCode];
        }
    });
}

#pragma mark - Authentication

- (void)authenticationChanged {
    
    if ([GKLocalPlayer localPlayer].isAuthenticated && !_userAuthenticated) {
        NSLog(@"Authentication changed: player authenticated.");
        [self setState:NetworkStateAuthenticated];
        _userAuthenticated = TRUE;
        [GKMatchmaker sharedMatchmaker].inviteHandler = ^(GKInvite *acceptedInvite, NSArray *playersToInvite) {
            NSLog(@"Received invite");
            self.pendingInvite = acceptedInvite;
            self.pendingPlayersToInvite = playersToInvite;
            
            if (_state >= NetworkStateConnected) {
                [self setState:NetworkStateReceivedMatchStatus];
                [_delegate setNotInMatch];
            }
            
        };
        [self connect];
        
        // Get the default leaderboard identifier.
        [[GKLocalPlayer localPlayer] loadDefaultLeaderboardIdentifierWithCompletionHandler:^(NSString *leaderboardIdentifier, NSError *error) {
            
            if (error != nil) {
                NSLog(@"%@", [error localizedDescription]);
            } else {
                _leaderboardIdentifier = leaderboardIdentifier;
            }
        }];
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && _userAuthenticated) {
        NSLog(@"Authentication changed: player not authenticated");
        _userAuthenticated = FALSE;
        [self disconnect];
        [self setState:NetworkStateNotAvailable];
    }
    
}

- (void)authenticateLocalUser {
    
    if (!_gameCenterAvailable) return;
    
    NSLog(@"Authenticating local user...");
    if ([GKLocalPlayer localPlayer].authenticated == NO) {
        [self setState:NetworkStatePendingAuthentication];
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        
        __weak GKLocalPlayer *blockLocalPlayer = localPlayer;
        localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
            if (blockLocalPlayer.authenticated) {
                //already authenticated
            } else if (viewController) {
                GameViewController *rootController=(GameViewController *)((AppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
                [rootController presentViewController:viewController animated:YES completion:nil];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"You must enable Game Center!" message:@"Authentication required. Please sign in through the Game Center app." preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [alert dismissViewControllerAnimated:YES completion:nil];
                    
                }];
                
                [alert addAction:ok];
                
                GameViewController *rootController=(GameViewController *)((AppDelegate *)[[UIApplication sharedApplication] delegate]).window.rootViewController;
                [rootController presentViewController:alert animated:YES completion:nil];
            }
        };
//        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:nil];
    } else {
        NSLog(@"Already authenticated!");
    }
}

#pragma mark - Matchmaking

- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers
                 viewController:(UIViewController *)viewController {
    
    if (!_gameCenterAvailable) return;
    
    [self setState:NetworkStatePendingMatch];
    
    self.presentingViewController = viewController;
    [_presentingViewController dismissViewControllerAnimated:NO completion:nil];
    
    if (_pendingInvite != nil) {
        
        [self sendNotifyReady:_pendingInvite.sender.playerID];
        
        self.mmvc = [[GKMatchmakerViewController alloc] initWithInvite:_pendingInvite];
        _mmvc.hosted = YES;
        _mmvc.matchmakerDelegate = self;
        
        [_presentingViewController presentViewController:_mmvc animated:YES completion:nil];
        self.pendingInvite = nil;
        self.pendingPlayersToInvite = nil;
        
    } else {
        GKMatchRequest *request = [[GKMatchRequest alloc] init];
        request.minPlayers = minPlayers;
        request.maxPlayers = maxPlayers;
        
        self.mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
        _mmvc.hosted = YES;
        _mmvc.matchmakerDelegate = self;
        
        [_presentingViewController presentViewController:_mmvc animated:YES completion:nil];
    }
}

// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    NSLog(@"matchmakerViewControllerWasCancelled");
    [self dismissMatchmaker];
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    NSLog(@"didFailWithError: %@", error.localizedDescription);
    [self dismissMatchmaker];
}

// Players have been found for a server-hosted game, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindPlayers:(NSArray *)playerIDs {
    NSLog(@"didFindPlayers");
    for (NSString *playerID in playerIDs) {
        NSLog(@"%@", playerID);
    }
    NSMutableArray *players = [[NSMutableArray alloc] initWithArray:playerIDs];
    [players insertObject:[GKLocalPlayer localPlayer].playerID atIndex:0];
    if (_state == NetworkStatePendingMatch) {
        [self dismissMatchmaker];
        // TODO: Send message to server to start match, with given player Ids
        [self sendStartMatch:players];
    }
}

// An invited player has accepted a hosted invite.  Apps should connect through the hosting server and then update the player's connected state (using setConnected:forHostedPlayer:)
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didReceiveAcceptFromHostedPlayer:(NSString *)playerID __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0) {
    NSLog(@"didReceiveAcceptFromHostedPlayer");
}

@end
