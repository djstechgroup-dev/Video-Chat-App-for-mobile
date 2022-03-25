//
//  QMBaseCallsController.h


#import <UIKit/UIKit.h>
#import "QMContentView.h"
#import "QMApi.h"
#import "QMSoundManager.h"
#import "IAButton.h"

@interface QMBaseCallsController : UIViewController<QBRTCClientDelegate>

@property (weak, nonatomic) IBOutlet IAButton *btnSpeaker;
@property (weak, nonatomic) IBOutlet IAButton *btnSwitchCamera;
@property (weak, nonatomic) IBOutlet IAButton *btnMic;
@property (weak, nonatomic) IBOutlet IAButton *btnVideo;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
/// nil for audio
@property(nonatomic, strong) QBRTCVideoTrack *localVideoTrack;
/// nil for audio
@property(nonatomic, strong) QBRTCVideoTrack *opponentVideoTrack;

@property (nonatomic, assign) BOOL isOpponentCaller;

/** Content View */
@property (weak, nonatomic) IBOutlet QMContentView *contentView;
@property (nonatomic, weak)  QBGLVideoView *opponentsView;
@property (nonatomic, weak)  IBOutlet UIImageView *camOffView;

@property (nonatomic, strong) QBUUser *opponent;

@property (weak, nonatomic) QBRTCSession *session;
/** Controls selectors */
- (IBAction)cameraSwitchTapped:(id)sender;
- (IBAction)muteTapped:(id)sender;
- (IBAction)videoTapped:(id)sender;
- (IBAction)speakerTapped:(id)sender;
- (IBAction)stopCallTapped:(id)sender;

/** Override actions in child */
- (void)startCall;
- (void)confirmCall;

- (void)callStartedWithUser;

- (void)callStoppedByOpponentForReason:(NSString *)reason;

- (void)startActivityIndicator;
- (void)stopActivityIndicator;

- (void)audioSessionRouteChanged:(NSNotification *)notification;

- (void)updateButtonsState;

@end
