//
//  QMCreateNewChatController.m


#import "QMCreateNewChatController.h"
#import "QMChatViewController.h"
#import "SVProgressHUD.h"
#import "QMApi.h"

NSString *const QMChatViewControllerID = @"QMChatViewController";

@implementation QMCreateNewChatController

- (void)dealloc {
    ILog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (void)viewDidLoad {
    
    NSArray *unsortedContacts = [[QMApi instance] contactsOnly];
    self.contacts = [QMUsersUtils sortUsersByFullname:unsortedContacts];
    [super viewDidLoad];
}
 
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Overriden Actions

- (IBAction)performAction:(id)sender {
    
	NSMutableArray *selectedUsersMArray = self.selectedFriends;
    NSString *chatName = [self chatNameFromUserNames:selectedUsersMArray];
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];

    __weak __typeof(self)weakSelf = self;
    [[QMApi instance] createGroupChatDialogWithName:chatName occupants:self.selectedFriends completion:^(QBChatDialog *chatDialog) {
        
        if (chatDialog) {
            
            QMChatViewController *chatVC = [weakSelf.storyboard instantiateViewControllerWithIdentifier:QMChatViewControllerID];
            chatVC.dialog = chatDialog;
            
            NSMutableArray *controllers = weakSelf.navigationController.viewControllers.mutableCopy;
            [controllers removeLastObject];
            [controllers addObject:chatVC];
            
            [weakSelf.navigationController setViewControllers:controllers animated:YES];
        }
        
        [SVProgressHUD dismiss];
    }];
}

- (NSString *)chatNameFromUserNames:(NSMutableArray *)users {
    
    NSMutableArray *names = [NSMutableArray arrayWithCapacity:users.count];
    
    for (QBUUser *user in users) {
        [names addObject:user.fullName];
    }
    
    [names addObject:[QMApi instance].currentUser.fullName];
    return [names componentsJoinedByString:@", "];
}

@end
