    //
//  QMChatViewController.m


#import "QMChatViewController.h"
#import "QMMainTabBarController.h"
#import "QMChatDataSource.h"
#import "QMChatButtonsFactory.h"
#import "QMGroupDetailsController.h"
#import "QMBaseCallsController.h"
#import "QMMessageBarStyleSheetFactory.h"
#import "QMApi.h"
#import "QMAlertsFactory.h"
#import "QMChatReceiver.h"
#import "QMOnlineTitle.h"
#import "IDMPhotoBrowser.h"
#import "QMChatInputToolbar.h"
#import "QMAudioCallController.h"
#import "QMVideoCallController.h"
#import "QMChatToolbarContentView.h"
#import "QMPlaceholderTextView.h"
#import "REAlertView+QMSuccess.h"

@interface QMChatViewController ()

<QMChatDataSourceDelegate, QMChatInputBarLockingProtocol>

@property (strong, nonatomic) QMOnlineTitle *onlineTitle;

@end

@implementation QMChatViewController

- (void)dealloc {
    ILog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
    [[QMChatReceiver instance] unsubscribeForTarget:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = [[QMChatDataSource alloc] initWithChatDialog:self.dialog forTableView:self.tableView inputBarDelegate:self];
    self.dataSource.delegate = self;
    self.dialog.type == QBChatDialogTypeGroup ? [self configureNavigationBarForGroupChat] : [self configureNavigationBarForPrivateChat];
    
    __weak __typeof(self)weakSelf = self;
    [[QMChatReceiver instance] chatAfterDidReceiveMessageWithTarget:self block:^(QBChatMessage *message) {
        if (message.delayed) {
            return;
        }
        if (message.cParamNotificationType == QMMessageNotificationTypeUpdateGroupDialog && [message.cParamDialogID isEqualToString:weakSelf.dialog.ID]) {
            weakSelf.dialog = [[QMApi instance] chatDialogWithID:message.cParamDialogID];
            weakSelf.title = weakSelf.dialog.name;
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setUpTabBarChatDelegate];
    
    if (self.dialog.type == QBChatDialogTypeGroup) {
        self.title = self.dialog.name;
    }
    else if (self.dialog.type == QBChatDialogTypePrivate) {
        
        [self updateTitleInfoForPrivateDialog];
    }
}

- (void)updateTitleInfoForPrivateDialog {
    
    NSUInteger oponentID = [[QMApi instance] occupantIDForPrivateChatDialog:self.dialog];
    QBUUser *opponent = [[QMApi instance] userWithID:oponentID];

    QBContactListItem *item = [[QMApi instance] contactItemWithUserID:opponent.ID];
    NSString *status = NSLocalizedString(item.online ? @"QM_STR_ONLINE": @"QM_STR_OFFLINE", nil);
    
    self.onlineTitle.titleLabel.text = opponent.fullName;
    self.onlineTitle.statusLabel.text = status;
}

- (void)viewWillDisappear:(BOOL)animated
{    
    [self removeTabBarChatDelegate];
    self.dialog.unreadMessagesCount = 0;
    
    [super viewWillDisappear:animated];
}

- (void)setUpTabBarChatDelegate
{
    if (self.tabBarController != nil && [self.tabBarController isKindOfClass:QMMainTabBarController.class]) {
        ((QMMainTabBarController *)self.tabBarController).chatDelegate = self;
    }
}

- (void)removeTabBarChatDelegate
{
     if (self.tabBarController != nil && [self.tabBarController isKindOfClass:QMMainTabBarController.class]) {
        ((QMMainTabBarController *)self.tabBarController).chatDelegate = nil;
     }
}

- (void)configureNavigationBarForPrivateChat {
    
    self.onlineTitle = [[QMOnlineTitle alloc] initWithFrame:CGRectMake(0,
                                                                       0,
                                                                       150,
                                                                       self.navigationController.navigationBar.frame.size.height)];
    self.navigationItem.titleView = self.onlineTitle;
    
    __weak __typeof(self)weakSelf = self;
    [[QMChatReceiver instance] chatContactListUpdatedWithTarget:self block:^{
        [weakSelf updateTitleInfoForPrivateDialog];
    }];
    
#if QM_AUDIO_VIDEO_ENABLED
    UIButton *audioButton = [QMChatButtonsFactory audioCall];
    [audioButton addTarget:self action:@selector(audioCallAction) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *videoButton = [QMChatButtonsFactory videoCall];
    [videoButton addTarget:self action:@selector(videoCallAction) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *videoCallBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:videoButton];
    UIBarButtonItem *audioCallBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:audioButton];
    
    [self.navigationItem setRightBarButtonItems:@[videoCallBarButtonItem,  audioCallBarButtonItem] animated:YES];
    
#else
    [self.navigationItem setRightBarButtonItem:nil];
#endif
}

- (void)configureNavigationBarForGroupChat {
    
    self.title = self.dialog.name;
    UIButton *groupInfoButton = [QMChatButtonsFactory groupInfo];
    [groupInfoButton addTarget:self action:@selector(groupInfoNavButtonAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *groupInfoBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:groupInfoButton];
    self.navigationItem.rightBarButtonItems = @[groupInfoBarButtonItem];
}

- (void)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Nav Buttons Actions

- (void)audioCallAction {
#if QM_AUDIO_VIDEO_ENABLED == 0
    [QMAlertsFactory comingSoonAlert];
#else

    BOOL callsAllowed = [[[self.inputToolBar contentView] textView] isEditable];
    if( !callsAllowed ) {
        [REAlertView showAlertWithMessage:NSLocalizedString(@"QM_STR_CANT_MAKE_CALLS", nil) actionSuccess:NO];
        return;
    }
    NSUInteger opponentID = [[QMApi instance] occupantIDForPrivateChatDialog:self.dialog];
    [[QMApi instance] callToUser:@(opponentID) conferenceType:QBConferenceTypeAudio];
    
#endif
}

- (void)videoCallAction {
#if QM_AUDIO_VIDEO_ENABLED == 0
    [QMAlertsFactory comingSoonAlert];
#else
    BOOL callsAllowed = [[[self.inputToolBar contentView] textView] isEditable];
    if( !callsAllowed ) {
        [REAlertView showAlertWithMessage:NSLocalizedString(@"QM_STR_CANT_MAKE_CALLS", nil) actionSuccess:NO];
        return;
    }
    
    NSUInteger opponentID = [[QMApi instance] occupantIDForPrivateChatDialog:self.dialog];
    [[QMApi instance] callToUser:@(opponentID) conferenceType:QBConferenceTypeVideo];
#endif
}

- (void)groupInfoNavButtonAction {
    
	[self performSegueWithIdentifier:kGroupDetailsSegueIdentifier sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self.view endEditing:YES];
    if ([segue.identifier isEqualToString:kGroupDetailsSegueIdentifier]) {
        
        QMGroupDetailsController *groupDetailVC = segue.destinationViewController;
        groupDetailVC.chatDialog = self.dialog;
    }
    else {
        
        NSUInteger opponentID = [[QMApi instance] occupantIDForPrivateChatDialog:self.dialog];
        QBUUser *opponent = [[QMApi instance] userWithID:opponentID];
        
        QMBaseCallsController *callsController = segue.destinationViewController;
        [callsController setOpponent:opponent];
    }
}


#pragma mark - QMChatDataSourceDelegate

- (void)chatDatasource:(QMChatDataSource *)chatDatasource prepareImageURLAttachement:(NSURL *)imageUrl {
 
    IDMPhoto *photo = [IDMPhoto photoWithURL:imageUrl];
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:@[photo]];
    browser.displayToolbar = NO;
    [self presentViewController:browser animated:YES completion:nil];
}

- (void)chatDatasource:(QMChatDataSource *)chatDatasource prepareImageAttachement:(UIImage *)image fromView:(UIView *)fromView {
    
    IDMPhoto *photo = [IDMPhoto photoWithImage:image];
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:@[photo] animatedFromView:fromView];
    [self presentViewController:browser animated:YES completion:nil];
}


#pragma mark - Chat Input Toolbar Lock Delegate

- (void)inputBarShouldLock
{
    [self.inputToolBar lock];
}

- (void)inputBarShouldUnlock
{
    [self.inputToolBar unlock];
}

@end
