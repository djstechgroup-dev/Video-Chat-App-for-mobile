    //
//  QMApi+ChatDialogs.m


#import "QMApi.h"
#import "QMChatDialogsService.h"
#import "QMApi+Notifications.m"
#import "QMMessagesService.h"
#import "QMUsersService.h"
#import "QMContentService.h"
#import "QMChatUtils.h"

NSString const *kQMEditDialogExtendedNameParameter = @"name";
NSString const *kQMEditDialogExtendedPushOccupantsParameter = @"push[occupants_ids][]";
NSString const *kQMEditDialogExtendedPullOccupantsParameter = @"pull_all[occupants_ids][]";

@interface QMApi()

@end

@implementation QMApi (ChatDialogs)



- (void)fetchAllDialogs:(void(^)(void))completion {
    
    __weak __typeof(self)weakSelf = self;
    [self.chatDialogsService fetchAllDialogs:^(QBDialogsPagedResult *result) {
        
        if ([weakSelf checkResult:result]) {
            [weakSelf.chatDialogsService addDialogs:result.dialogs];
            if (completion) completion();
        }
    }];
}

- (void)fetchDialogsWithLastActivityFromDate:(NSDate *)date completion:(QBDialogsPagedResultBlock)completion
{
    [self.chatDialogsService fetchDialogsWithLastActivityFromDate:date completion:completion];
}

- (void)fetchChatDialogWithID:(NSString *)dialogID completion:(void(^)(QBChatDialog *chatDialog))completion
{
    
    __weak typeof(self)weakSelf = self;

    [self.chatDialogsService fetchDialogWithID:dialogID completion:^(QBChatDialog *dialog) {
        if (!dialog) {
            if (completion) completion(dialog);
            return;
        }
        [weakSelf.usersService retriveIfNeededUsersWithIDs:dialog.occupantIDs completion:^(BOOL retrieveWasNeeded) {
            if (completion) completion(dialog);
        }];
    }];
}


#pragma mark - Create Chat Dialogs


- (void)createPrivateChatDialogIfNeededWithOpponent:(QBUUser *)opponent completion:(void(^)(QBChatDialog *chatDialog))completion
{
    [self.chatDialogsService createPrivateChatDialogIfNeededWithOpponent:opponent completion:completion];
}

- (void)createGroupChatDialogWithName:(NSString *)name occupants:(NSArray *)occupants completion:(void(^)(QBChatDialog *chatDialog))completion {
    
    NSArray *occupantIDs = [self idsWithUsers:occupants];
    
    QBChatDialog *chatDialog = [[QBChatDialog alloc] init];
    chatDialog.name = name;
    chatDialog.occupantIDs = occupantIDs;
    chatDialog.type = QBChatDialogTypeGroup;
    
    __weak typeof(self)weakSelf = self;
    [self.chatDialogsService createGroupChatDialog:chatDialog completion:^(QBChatDialog *dialog) {
        
        // add to history:
        [weakSelf.chatDialogsService addDialogToHistory:dialog];
        
        // send notification from here:
        NSString *notificationText = NSLocalizedString(@"QM_STR_NOTIFICATION_MESSAGE", nil);
        // send to group:
        [weakSelf sendGroupChatDialogDidCreateNotificationToAllParticipantsWithText:notificationText occupants:dialog.occupantIDs chatDialog:dialog completion:^(QBChatMessage *chatMessage) {
            // send to private:
            [weakSelf sendGroupChatDialogDidCreateNotificationToUsers:occupants text:notificationText toChatDialog:dialog];
            completion(dialog);
        }];
    }];
}


#pragma mark - Edit dialog methods

- (void)changeChatName:(NSString *)dialogName forChatDialog:(QBChatDialog *)chatDialog completion:(QBChatDialogResultBlock)completion {
    
    NSMutableDictionary *extendedRequest = [[NSMutableDictionary alloc] init];
    extendedRequest[kQMEditDialogExtendedNameParameter] = dialogName;

    __weak __typeof(self)weakSelf = self;
    [self.chatDialogsService updateChatDialogWithID:chatDialog.ID extendedRequest:extendedRequest completion:^(QBChatDialogResult *result) {

        if ([weakSelf checkResult:result]) {
            chatDialog.name = dialogName;
            
             NSString *notificationText = NSLocalizedString(@"QM_STR_NOTIFICATION_MESSAGE", nil);
            
            [weakSelf sendGroupChatDialogDidUpdateNotificationToAllParticipantsWithText:notificationText toChatDialog:chatDialog updateType:@"room_name" content:dialogName];
        }
        completion(result);
    }];
}

- (void)changeAvatar:(UIImage *)avatar forChatDialog:(QBChatDialog *)chatDialog completion:(QBChatDialogResultBlock)completion
{
    __weak typeof(self)weakSelf = self;
    [self.contentService uploadPNGImage:avatar progress:^(float progress) {
        //
    } completion:^(QBCFileUploadTaskResult *result) {
        // update chat dialog:
        if (!result.success) {
            return;
        }
        NSMutableDictionary *extendedRequest = [NSMutableDictionary new];
        extendedRequest[@"photo"] = result.uploadedBlob.publicUrl;
        [weakSelf.chatDialogsService updateChatDialogWithID:chatDialog.ID extendedRequest:extendedRequest completion:^(QBChatDialogResult *dialogResult) {
            if (dialogResult.success) {
                // send notification:
                NSString *notificationText = NSLocalizedString(@"QM_STR_NOTIFICATION_MESSAGE", nil);
                chatDialog.photo = dialogResult.dialog.photo;
                [weakSelf sendGroupChatDialogDidUpdateNotificationToAllParticipantsWithText:notificationText toChatDialog:chatDialog updateType:@"room_photo" content:dialogResult.dialog.photo];
                completion(dialogResult);
            }
        }];
    }];
}

- (void)joinOccupants:(NSArray *)occupants toChatDialog:(QBChatDialog *)chatDialog completion:(QBChatDialogResultBlock)completion {
    
    NSArray *occupantsToJoinIDs = [self idsWithUsers:occupants];
    
    NSMutableDictionary *extendedRequest = [[NSMutableDictionary alloc] init];
    extendedRequest[kQMEditDialogExtendedPushOccupantsParameter] = occupantsToJoinIDs;
    
    __weak __typeof(self)weakSelf = self;
    [self.chatDialogsService updateChatDialogWithID:chatDialog.ID extendedRequest:extendedRequest completion:^(QBChatDialogResult *result) {
        
        if ([weakSelf checkResult:result]) {
            [weakSelf.chatDialogsService addDialogToHistory:result.dialog];
            
            NSString *messageTypeText = NSLocalizedString(@"QM_STR_ADD_USERS_TO_GROUP_CONVERSATION_TEXT", @"{Full name}");
            NSString *text = [QMChatUtils messageForText:messageTypeText participants:occupants];
            
            [weakSelf sendGroupChatDialogDidCreateNotificationToUsers:occupants text:text toChatDialog:chatDialog];
            [weakSelf sendGroupChatDialogDidUpdateNotificationToAllParticipantsWithText:text toChatDialog:chatDialog updateType:@"occupants_ids" content:[QMChatUtils idsStringWithoutSpaces:occupants]];
            
        }
        completion(result);
    }];
}

- (void)leaveChatDialog:(QBChatDialog *)chatDialog completion:(QBChatDialogResultBlock)completion {
    
    NSString *messageTypeText = NSLocalizedString(@"QM_STR_LEAVE_GROUP_CONVERSATION_TEXT", @"{Full name}");
    NSString *text = [NSString stringWithFormat:messageTypeText, self.currentUser.fullName];
    NSString *myID = [NSString stringWithFormat:@"%lu", (unsigned long)self.currentUser.ID];
    [self sendGroupChatDialogDidUpdateNotificationToAllParticipantsWithText:text toChatDialog:chatDialog updateType:@"deleted_id" content:myID];
    
    NSMutableDictionary *extendedRequest = [[NSMutableDictionary alloc] init];
    extendedRequest[kQMEditDialogExtendedPullOccupantsParameter] = myID;
    
    [chatDialog.chatRoom leaveRoom];
    __weak __typeof(self)weakSelf = self;
    [self.chatDialogsService updateChatDialogWithID:chatDialog.ID extendedRequest:extendedRequest completion:^(QBChatDialogResult *result) {
        if (result.success) {
            [weakSelf.chatDialogsService deleteLocalDialog:chatDialog];
            completion(result);
        }
    }];
}

- (NSUInteger )occupantIDForPrivateChatDialog:(QBChatDialog *)chatDialog {
    
    NSAssert(chatDialog.type == QBChatDialogTypePrivate, @"Chat dialog type != QBChatDialogTypePrivate");
    
    NSInteger myID = self.currentUser.ID;
    
    for (NSNumber *ID in chatDialog.occupantIDs) {
        
        if (ID.integerValue != myID) {
            return ID.integerValue;
        }
    }
    
    NSAssert(nil, @"Need update this cace");
    return 0;
}

- (void)deleteChatDialog:(QBChatDialog *)dialog completion:(void(^)(BOOL success))completionHandler
{
    __weak typeof(self)weakSelf = self;
    [self.chatDialogsService deleteChatDialog:dialog completion:^(BOOL success) {
        
        [weakSelf.messagesService deleteMessageHistoryWithChatDialogID:dialog.ID];
        completionHandler(success);
    }];
}


#pragma mark - Notifications

- (void)sendGroupChatDialogDidCreateNotificationToUsers:(NSArray *)users text:(NSString *)text toChatDialog:(QBChatDialog *)chatDialog {
    
    for (QBUUser *recipient in users) {
        QBChatMessage *notification = [self notificationToRecipient:recipient text:text chatDialog:chatDialog];
        [notification setCustomParametersWithChatDialog:chatDialog];
        [self sendGroupChatDialogDidCreateNotification:notification toChatDialog:chatDialog persistent:NO completionBlock:^(QBChatMessage *msg) {}];
    }
}

- (void)sendGroupChatDialogDidCreateNotificationToAllParticipantsWithText:(NSString *)text occupants:(NSArray *)occupants chatDialog:(QBChatDialog *)chatDialog completion:(void(^)(QBChatMessage *chatMessage))block
{
    QBChatMessage *groupNotification = [self notificationToRecipient:nil text:text chatDialog:chatDialog];
    
    groupNotification.cParamDialogOccupantsIDs = occupants; // occupants IDs received
    
   [self sendGroupChatDialogDidCreateNotification:groupNotification toChatDialog:chatDialog persistent:YES completionBlock:block];
}

- (void)sendGroupChatDialogDidUpdateNotificationToAllParticipantsWithText:(NSString *)text toChatDialog:(QBChatDialog *)chatDialog updateType:(NSString *)updateType content:(NSString *)content
{
    QBChatMessage *groupNotification = [self notificationToRecipient:nil text:text chatDialog:chatDialog];
    if (updateType != nil && content != nil) {
        groupNotification.customParameters[updateType] = content;  // fast fix
    }
    [self sendGroupChatDialogDidUpdateNotification:groupNotification toChatDialog:chatDialog completionBlock:^(QBChatMessage *msg) {}];
}

- (QBChatMessage *)notificationToRecipient:(QBUUser *)recipient text:(NSString *)text chatDialog:(QBChatDialog *)chatDialog {
    
    QBChatMessage *msg = [QBChatMessage message];
    
    msg.recipientID = recipient.ID;
    msg.text = text;
    msg.cParamDateSent = @((NSInteger)CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970);
    msg.cParamDialogID = chatDialog.ID;
    
    return msg;
}


#pragma mark - Dialogs toos

- (NSArray *)dialogHistory {
    
    return [self.chatDialogsService dialogHistory];
}

- (QBChatDialog *)chatDialogWithID:(NSString *)dialogID {
    
    return [self.chatDialogsService chatDialogWithID:dialogID];
}

- (NSArray *)allOccupantIDsFromDialogsHistory{
    
    NSArray *allDialogs = self.chatDialogsService.dialogHistory;
    NSMutableSet *ids = [NSMutableSet set];
    
    for (QBChatDialog *dialog in allDialogs) {
        [ids addObjectsFromArray:dialog.occupantIDs];
    }
    
    return ids.allObjects;
}

@end
