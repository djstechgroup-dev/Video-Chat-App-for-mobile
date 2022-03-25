//
//  QMIncomingCallController.m

#import "QMIncomingCallController.h"
#import "QMApi.h"
#import "QMImageView.h"
#import "QMSoundManager.h"
#import "QMVideoP2PController.h"
#import "QMAVCallManager.h"

#import "AppDelegate.h"

@interface QMIncomingCallController ()<QBRTCClientDelegate>

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *wefieNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *incomingCallLabel;
@property (weak, nonatomic) IBOutlet QMImageView *userAvatarView;
/// buttons for audio
@property (weak, nonatomic) IBOutlet UIView *incomingCallView;
/// buttons for video
@property (weak, nonatomic) IBOutlet UIView *incomingVideoCallView;

@end

@implementation QMIncomingCallController{

    NSUInteger userNumber;
}

@synthesize opponent;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userAvatarView.imageViewType = QMImageViewTypeCircle;
    
    [QBRTCClient.instance addDelegate:self];
    
    
    userNumber = 0;
    [self retrieveAllUsersFromPage:1];
    
    opponent = [[QMApi instance] userWithID:self.opponentID];
    
    if( opponent ){
        
        
        self.userNameLabel.text = opponent.fullName;
        self.wefieNumberLabel.text = opponent.phone;
    }
    else{
       //@@@
        QBUUser *opponentFromWN = [self findUserFromID:self.opponentID];
        
        self.userNameLabel.text = @"Unknown caller";
        self.wefieNumberLabel.text = opponentFromWN.phone;
       // @@@
    }
 
    if (self.callType == QBConferenceTypeVideo) {
        [self.incomingCallView setHidden:YES];
        self.incomingCallLabel.text = NSLocalizedString(@"QM_STR_INCOMING_VIDEO_CALL", nil);
    } else if (self.callType == QBConferenceTypeAudio) {
        [self.incomingVideoCallView setHidden:YES];
        self.incomingCallLabel.text = NSLocalizedString(@"QM_STR_INCOMING_CALL", nil);
    }

    NSURL *url = [NSURL URLWithString:opponent.website];
    UIImage *placeholder = [UIImage imageNamed:@"upic_call"];
    
    [self.userAvatarView setImageWithURL:url
                             placeholder:placeholder
                                 options:SDWebImageLowPriority
                                progress:^(NSInteger receivedSize, NSInteger expectedSize) {}
                          completedBlock:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
     }];

}

#pragma mark - Actions

- (IBAction)acceptCall:(id)sender {
    __weak __typeof(self) weakSelf = self;
    [[[QMApi instance] avCallManager] checkPermissionsWithConferenceType:self.callType completion:^(BOOL canContinue) {
        if( canContinue ) {
            [[QMSoundManager instance] stopAllSounds];
            if (weakSelf.callType == QBConferenceTypeVideo) {
                [weakSelf performSegueWithIdentifier:kGoToDuringVideoCallSegueIdentifier sender:weakSelf];
            } else {
                [weakSelf performSegueWithIdentifier:kGoToDuringAudioCallSegueIdentifier sender:nil];
            }
        }
    }];
}

- (IBAction)acceptCallWithVideo:(id)sender {
    __weak __typeof(self) weakSelf = self;
    [[QMSoundManager instance] stopAllSounds];
    [[[QMApi instance] avCallManager] checkPermissionsWithConferenceType:self.callType completion:^(BOOL canContinue) {
        if( canContinue ) {
            [[QMSoundManager instance] stopAllSounds];
            [weakSelf performSegueWithIdentifier:kGoToDuringVideoCallSegueIdentifier sender:nil];
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // sender is not nil when accepting video call with denying my(local) video track
    if( [segue.identifier isEqualToString:kGoToDuringVideoCallSegueIdentifier] && sender != nil ){
        QMVideoP2PController *vc = segue.destinationViewController;
        vc.disableSendingLocalVideoTrack = YES;
    }
}

- (IBAction)declineCall:(id)sender {
    
    [[QMSoundManager instance] stopAllSounds];
    [[QMApi instance] rejectCall];
    [QMSoundManager playEndOfCallSound];
    self.incomingCallLabel.text = NSLocalizedString(@"QM_STR_CALL_WAS_CANCELLED", nil);
}

- (void)cleanUp {
    [[QMSoundManager instance] stopAllSounds];
    [QBRTCClient.instance removeDelegate:self];
}

- (void)sessionWillClose:(QBRTCSession *)session {
    if( self.session == session ) {
        [self cleanUp];
    }
}

- (void)dealloc {
    [self cleanUp];
}

- (QBUUser *)findUserFromID:(NSUInteger)userID{

    NSMutableArray *users = [AppDelegate sharedInstance].users;
    for(NSUInteger i = 0 ; i < users.count ; i++){
        
        QBUUser *user = [users objectAtIndex:i];
        NSUInteger  tempUserID = user.ID;
        
        if(userID == tempUserID){
        
            return user;
        }

    }
    
    return nil;
}

// @@@
- (void)retrieveAllUsersFromPage:(int)page{
    
    
    [QBRequest usersForPage:[QBGeneralResponsePage responsePageWithCurrentPage:page perPage:100] successBlock:^(QBResponse *response, QBGeneralResponsePage *pageInformation, NSArray *users) {
        
        [AppDelegate sharedInstance].users  = users;
        
        userNumber += users.count;
        if (pageInformation.totalEntries > userNumber) {
            [self retrieveAllUsersFromPage:pageInformation.currentPage + 1];
        }
    } errorBlock:^(QBResponse *response) {
        // Handle error
    }];
}
// @@@

@end
