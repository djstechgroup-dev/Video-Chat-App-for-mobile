//
//  QMInviteFriendsDataSource.m


#import "QMInviteFriendsDataSource.h"
#import "QMInviteFriendCell.h"
#import "QMInviteStaticCell.h"
#import "ABPerson.h"
#import "QMApi.h"
#import "QMFacebookService.h"
#import "QMAddressBook.h"
#import "SVProgressHUD.h"

typedef NS_ENUM(NSUInteger, QMCollectionGroup) {
    
    QMStaticCellsSection = 0,
    QMFriendsListSection = 1,
    QMABFriendsToInviteSection = 3
};

NSString *const kQMInviteFriendCellID = @"QMInviteFriendCell";
NSString *const kQMStaticFBCellID = @"QMStaticFBCell";
NSString *const kQMStaticABCellID = @"QMStaticABCell";

const CGFloat kQMInviteFriendCellHeight = 60;
const CGFloat kQMStaticCellHeihgt = 44;
const NSUInteger kQMNumberOfSection = 2;

@interface QMInviteFriendsDataSource()

<UITableViewDataSource, QMCheckBoxProtocol, QMCheckBoxStateDelegate>

@property (weak, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSMutableDictionary *collections;
@property (strong, nonatomic) QMInviteStaticCell *abStaticCell;
@property (strong, nonatomic) QMInviteStaticCell *fbStaticCell;

@property (strong, nonatomic) NSArray *abUsers;

@end

@implementation QMInviteFriendsDataSource

- (instancetype)initWithTableView:(UITableView *)tableView {
    
    self = [super init];
    if (self) {
        
        _collections = [NSMutableDictionary dictionary];
        _abUsers = @[];
        
        self.tableView = tableView;
        self.tableView.dataSource = self;
        self.checkBoxDelegate = self;
        
        self.abStaticCell = [self.tableView dequeueReusableCellWithIdentifier:kQMStaticABCellID];
        self.abStaticCell.delegate = self;
        
        self.fbStaticCell = [self.tableView dequeueReusableCellWithIdentifier:kQMStaticFBCellID];
        
        NSArray *staticCells = @[self.abStaticCell,self.fbStaticCell];

        [self setCollection:staticCells toSection:QMStaticCellsSection];
        [self setCollection:@[].mutableCopy toSection:QMABFriendsToInviteSection];
    }
    
    return self;
}

#pragma mark - fetch user 

- (void)fetchFacebookFriends:(void(^)(void))completion {
    
    [[QMApi instance] fbIniviteDialogWithCompletion:^(BOOL success) {
        if (success) {
            [SVProgressHUD showSuccessWithStatus:@"Success"];
            return;
        }
    }];

}

- (void)fetchAdressbookFriends:(void(^)(void))completion {
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    __weak __typeof(self)weakSelf = self;
    [QMAddressBook getContactsWithEmailsWithCompletionBlock:^(NSArray *contacts, BOOL success, NSError *error) {
        
        weakSelf.abUsers = contacts;
        [SVProgressHUD dismiss];
        
        if (completion) completion();
        
    }];
}

#pragma mark - setters

- (void)setAbUsers:(NSArray *)abUsers {
    
    abUsers = [self sortUsersByKey:@"fullName" users:abUsers];
    if (![_abUsers isEqualToArray:abUsers]) {
        _abUsers = abUsers;
        [self updateDatasource];
    }
}

- (NSArray *)sortUsersByKey:(NSString *)key users:(NSArray *)users {
    
    NSSortDescriptor *fullNameDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
    NSArray *sortedUsers = [users sortedArrayUsingDescriptors:@[fullNameDescriptor]];
    
    return sortedUsers;
}

- (void)reloadFriendSectionWithRowAnimation:(UITableViewRowAnimation)animation {
    
    [self.tableView beginUpdates];
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:QMFriendsListSection];
    [self.tableView reloadSections:indexSet withRowAnimation:animation];
    [self.tableView endUpdates];
}

- (void)reloadRowPathAtIndexPath:(NSIndexPath *)indexPath withRowAnimation:(UITableViewRowAnimation)animation {
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:animation];
    [self.tableView endUpdates];
}

- (void)updateDatasource {
    
    NSArray * friendsCollection = self.abUsers;
    [self setCollection:friendsCollection toSection:QMFriendsListSection];
    [self reloadFriendSectionWithRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kQMNumberOfSection;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSArray *collection = [self collectionAtSection:section];
    return collection.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == QMStaticCellsSection) {

        QMInviteStaticCell *staticCell = [self itemAtIndexPath:indexPath];
        NSArray *array = [self collectionAtSection:QMABFriendsToInviteSection];
        staticCell.badgeCount = array.count;
        NSLog(@"%d",array.count);
        return staticCell;
    }
    
    QMInviteFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:kQMInviteFriendCellID];

    id userData = [self itemAtIndexPath:indexPath];

    if ([userData isKindOfClass:[QBUUser class]]) {
        QBUUser *user = userData;
        cell.contactlistItem = [[QMApi instance] contactItemWithUserID:user.ID];
    }
    
    cell.userData = userData;
    cell.check = [self checkedAtIndexPath:indexPath];
    cell.delegate = self;
    
    return cell;
}

#pragma mark - keys
/**
 Access key for collection At section
 */
- (NSString *)keyAtSection:(NSUInteger)section {
    
    NSString *sectionKey = [NSString stringWithFormat:@"section - %d", section];
    return sectionKey;
}

#pragma mark - collections

- (NSMutableArray *)collectionAtSection:(NSUInteger)section {
    
    NSString *key = [self keyAtSection:section];
    NSMutableArray *collection = self.collections[key];
    
    return collection;
}

- (void)setCollection:(NSArray *)collection toSection:(NSUInteger)section {
    
    NSString *key = [self keyAtSection:section];
    self.collections[key] = collection;
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *collection = [self collectionAtSection:indexPath.section];
    id item = collection[indexPath.row];
    
    return item;
}

- (NSUInteger)sectionToInviteWihtUserData:(id)data {
    
    if ([data isKindOfClass:ABPerson.class]) {
        return QMABFriendsToInviteSection;
    }
    
    NSAssert(nil, @"Need update this case");
    return 0;
}

- (BOOL)checkedAtIndexPath:(NSIndexPath *)indexPath {
    
    id item = [self itemAtIndexPath:indexPath];
    NSInteger sectionToInvite = [self sectionToInviteWihtUserData:item];
    NSArray *toInvite = [self collectionAtSection:sectionToInvite];
    BOOL checked = [toInvite containsObject:item];
    
    return checked;
}

#pragma mark - QMCheckBoxProtocol

- (void)containerView:(UIView *)containerView didChangeState:(id)sender {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(id)containerView];
   __weak __typeof(self)weakSelf = self;
    void (^update)(NSUInteger, NSArray*) = ^(NSUInteger collectionSection, NSArray *collection){
        
        QMInviteStaticCell *cell = (QMInviteStaticCell *)containerView;
        
        [weakSelf setCollection:cell.isChecked ? collection.mutableCopy : @[].mutableCopy toSection:collectionSection];
        [weakSelf reloadRowPathAtIndexPath:indexPath withRowAnimation:UITableViewRowAnimationNone];
        [weakSelf reloadFriendSectionWithRowAnimation:UITableViewRowAnimationNone];
    };
    
    if (containerView == self.abStaticCell) {
        
        if (self.abUsers.count == 0) {
            [self fetchAdressbookFriends:^{
                update(QMABFriendsToInviteSection, weakSelf.abUsers);
            }];
        }
        else {
            update(QMABFriendsToInviteSection, self.abUsers);
        }
        
    }
    else  {
        
        QMInviteFriendCell *cell = (QMInviteFriendCell *)containerView;
        
        id item = [self itemAtIndexPath:indexPath];
        
        NSUInteger section = [self sectionToInviteWihtUserData:item];
        NSMutableArray *toInvite = [self collectionAtSection:section];
        cell.isChecked ? [toInvite addObject:item] : [toInvite removeObject:item];
        NSLog(@"rtgergdfg   %d",indexPath.length);
        NSIndexPath *indexPathToReload = [NSIndexPath indexPathForRow:0 inSection:QMFriendsListSection];
        
        [self reloadRowPathAtIndexPath:indexPathToReload withRowAnimation:UITableViewRowAnimationNone];
    }
    
    [self checkListDidChange];
}

- (void)clearABFriendsToInvite  {
    
    [self setCollection:@[].mutableCopy toSection:QMABFriendsToInviteSection];
    [self.tableView reloadData];
    [self checkListDidChange];
}


- (void)checkListDidChange {
    
    NSArray *addressBookFriendsToInvite = self.collections [[self keyAtSection:QMABFriendsToInviteSection]];
    [self.checkBoxDelegate checkListDidChangeCount:(addressBookFriendsToInvite.count)];
}

#pragma mark - Public methods
#pragma mark Invite Data

- (NSArray *)emailsToInvite {
    
    NSMutableArray *result = [NSMutableArray array];
    
    NSArray *addressBookUsersToInvite = [self collectionAtSection:QMABFriendsToInviteSection];
    for (ABPerson *user in addressBookUsersToInvite) {
        [result addObject:user.emails.firstObject];
    }
    
    return result;
}

#pragma mark -

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == QMStaticCellsSection ) {
        return kQMStaticCellHeihgt;
    } else if (indexPath.section == QMFriendsListSection) {
        return kQMInviteFriendCellHeight;
    }
    
    NSAssert(nil, @"Need Update this case");
    return 0;
}

- (void)didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == QMStaticCellsSection) {
        
        switch (indexPath.row) {
            case 0: [self fetchAdressbookFriends:nil]; break;
            case 1:[self fetchFacebookFriends:nil]; break;
            default:NSAssert(nil, @"Need Update this case"); break;
        }
    }
}

@end