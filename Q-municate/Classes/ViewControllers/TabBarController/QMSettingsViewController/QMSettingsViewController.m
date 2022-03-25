//
//  QMSettingsViewController.m


#import "QMSettingsViewController.h"
#import "REAlertView+QMSuccess.h"
#import "SVProgressHUD.h"
#import "SDWebImageManager.h"
#import "QMApi.h"
#import "QMSettingsManager.h"
#import "QMWelcomeScreenViewController.h"
#import "QMFAQViewController.h"

@interface QMSettingsViewController (){
    BOOL flag;
}

@property (weak, nonatomic) IBOutlet UITableViewCell *logoutCell;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell *changePasswordCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *profileCell;
@property (weak, nonatomic) IBOutlet UISwitch *pushNotificationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *cacheSize;

@end

@implementation QMSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.pushNotificationSwitch.on = [QMApi instance].settingsManager.pushNotificationsEnabled;
    if ([QMApi instance].settingsManager.accountType == QMAccountTypeFacebook) {
        [self cell:self.changePasswordCell setHidden:YES];
    }
    
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:kSettingsCellBundleVersion];
    self.versionLabel.text = appVersion;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    // if first signup then
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    flag = [defaults boolForKey:@"isFristSignup"];
   
    
    if (flag){
        QMFAQViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"QMFAQViewController"];
        [self.navigationController pushViewController:vc animated:NO];
        flag = false;
        
        [defaults setBool:false forKey:@"isFristSignup"];
        [defaults synchronize];
        
        return;
    }
    __weak __typeof(self)weakSelf = self;
    [[[SDWebImageManager sharedManager] imageCache] calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
        weakSelf.cacheSize.text = [NSString stringWithFormat:@"Cache size: %.2f mb", (float)totalSize / 1024.f / 1024.f];
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (cell == self.logoutCell) {
        
        if (!QMApi.instance.isInternetConnected) {
            [REAlertView showAlertWithMessage:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil) actionSuccess:NO];
            return;
        }
        
        __weak __typeof(self)weakSelf = self;
        [REAlertView presentAlertViewWithConfiguration:^(REAlertView *alertView) {
            
            alertView.message = NSLocalizedString(@"QM_STR_ARE_YOU_SURE", nil);
            [alertView addButtonWithTitle:NSLocalizedString(@"QM_STR_LOGOUT", nil) andActionBlock:^{
                
                [weakSelf pressClearCache:nil];
                [SVProgressHUD  showWithMaskType:SVProgressHUDMaskTypeClear];
                [[QMApi instance] logout:^(BOOL success) {
                    [SVProgressHUD dismiss];
//                    [weakSelf performSegueWithIdentifier:kSplashSegueIdentifier sender:nil];
                    [weakSelf performSegueWithIdentifier:@"wecomelogin" sender:nil];
                }];
            }];
            
            [alertView addButtonWithTitle:NSLocalizedString(@"QM_STR_CANCEL", nil) andActionBlock:^{}];
        }];
    }
}

#pragma mark - Actions

- (IBAction)changePushNotificationValue:(UISwitch *)sender {

    if (!QMApi.instance.isInternetConnected) {
        [REAlertView showAlertWithMessage:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil) actionSuccess:NO];
        self.pushNotificationSwitch.on = !self.pushNotificationSwitch.on;
        return;
    }
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    if ([sender isOn]) {
        [[QMApi instance] subscribeToPushNotificationsForceSettings:YES complete:^(BOOL success) {
            [SVProgressHUD dismiss];
        }];
    }
    else {
        [[QMApi instance] unSubscribeToPushNotifications:^(BOOL success) {
            [SVProgressHUD dismiss];
        }];
    }
    
}

- (IBAction)pressClearCache:(id)sender {
    
    __weak __typeof(self)weakSelf = self;
    [[[SDWebImageManager sharedManager] imageCache] clearMemory];
    [[[SDWebImageManager sharedManager] imageCache] clearDiskOnCompletion:^{
        
        [[[SDWebImageManager sharedManager] imageCache] calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
            weakSelf.cacheSize.text = [NSString stringWithFormat:@"Cache size: %.2f mb", (float)totalSize / 1024.f / 1024.f];
        }];
    }];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"wecomelogin"])
    {
        QMWelcomeScreenViewController *vc = (QMWelcomeScreenViewController*)segue.destinationViewController;
        vc.hidesBottomBarWhenPushed = YES;
    }
}

@end