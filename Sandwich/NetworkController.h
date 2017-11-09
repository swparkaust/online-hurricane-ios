#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

typedef enum {
    NetworkStateNotAvailable,
    NetworkStatePendingAuthentication,
    NetworkStateAuthenticated,
    NetworkStateConnectingToServer,
    NetworkStateConnected,
    NetworkStatePendingMatchStatus,
    NetworkStateReceivedMatchStatus,
    NetworkStatePendingMatch,
    NetworkStatePendingMatchStart,
    NetworkStateMatchActive,
} NetworkState;

@class Match;

@protocol NetworkControllerDelegate
- (void)stateChanged:(NetworkState)state;
- (void)setNotInMatch;
- (void)matchStarted:(Match *)match;
- (void)activatePlayer:(unsigned char)playerIndex;
- (void)player:(unsigned char)playerIndex turnedCardWithRank:(int)rank suit:(int)suit playerScore:(int)playerScore;
- (void)playerClaimedPile:(unsigned char)playerIndex playerScore:(int)playerScore;
- (void)player:(unsigned char)playerIndex discardedCardWithRank:(int)rank suit:(int)suit playerScore:(int)playerScore;
- (void)gameOver:(unsigned char)winnerIndex winnerScore:(int)winnerScore;
- (void)chat:(NSString *)text;
@end

@interface NetworkController : NSObject <NSStreamDelegate, GKMatchmakerViewControllerDelegate, GKLocalPlayerListener> {
    BOOL _gameCenterAvailable;
    BOOL _userAuthenticated;
    NetworkState _state;
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
    BOOL _inputOpened;
    BOOL _outputOpened;
    NSMutableData *_outputBuffer;
    NSMutableData *_inputBuffer;
    BOOL _okToWrite;
    UIViewController *_presentingViewController;
    GKMatchmakerViewController *_mmvc;
    GKInvite *_pendingInvite;
    NSArray *_pendingPlayersToInvite;
    NSString *_leaderboardIdentifier;
}

@property (assign, readonly) BOOL gameCenterAvailable;
@property (assign, readonly) BOOL userAuthenticated;
@property (assign) id <NetworkControllerDelegate> delegate;
@property (assign, readonly) NetworkState state;
@property (retain) NSInputStream *inputStream;
@property (retain) NSOutputStream *outputStream;
@property (assign) BOOL inputOpened;
@property (assign) BOOL outputOpened;
@property (retain) NSMutableData *outputBuffer;
@property (retain) NSMutableData *inputBuffer;
@property (assign) BOOL okToWrite;
@property (retain) UIViewController *presentingViewController;
@property (retain) GKMatchmakerViewController *mmvc;
@property (retain) GKInvite *pendingInvite;
@property (retain) NSArray *pendingPlayersToInvite;
@property (nonatomic, strong) NSString *leaderboardIdentifier;

+ (NetworkController *)sharedInstance;
- (void)authenticateLocalUser;
- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers
                 viewController:(UIViewController *)viewController;
- (void)sendTurnedCard;
- (void)sendDidSlap;
- (void)sendRestartMatch;
- (void)sendQuitMatch;
- (void)sendChat:(NSString *)text;

@end