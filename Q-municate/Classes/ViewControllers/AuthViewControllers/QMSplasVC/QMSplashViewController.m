//
//  QMSplashViewController.m


#import "QMSplashViewController.h"
#import "QMWelcomeScreenViewController.h"
#import "QMSettingsManager.h"
#import "REAlertView+QMSuccess.h"
#import "QMApi.h"

@interface QMSplashViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *splashLogoView;
@property (weak, nonatomic) IBOutlet UIButton *reconnectBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation QMSplashViewController

- (void)dealloc {
    ILog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    //[self.splashLogoView setImage:[UIImage imageNamed:IS_HEIGHT_GTE_568 ? @"bg" : @"splash-960"]];
    self.activityIndicator.hidesWhenStopped = YES;
    [self createSession];
}

- (void)createSession {
    
    self.reconnectBtn.alpha = 0;
    
    if (!QMApi.instance.isInternetConnected) {
        [REAlertView showAlertWithMessage:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil) actionSuccess:NO];
        self.reconnectBtn.alpha = 1;
        return;
    }
    
    [self.activityIndicator startAnimating];

    __weak __typeof(self)weakSelf = self;
    [[QMApi instance] createSessionWithBlock:^(BOOL success) {

        if (!success) {
            [weakSelf reconnect];
        }
        else {
            
            QMSettingsManager *settingsManager = [[QMSettingsManager alloc] init];
            BOOL rememberMe = settingsManager.rememberMe;
            
            if (rememberMe) {
                [weakSelf performSegueWithIdentifier:kTabBarSegueIdnetifier sender:nil];
            } else {
                [weakSelf performSegueWithIdentifier:kWelcomeScreenSegueIdentifier sender:nil];
            }
        }
    }];
}

- (void)reconnect {
    
    self.reconnectBtn.alpha = 1;
    [self.activityIndicator stopAnimating];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)pressReconnectBtn:(id)sender {
    [self createSession];
}

@end
