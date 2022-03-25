//
//  QMMessagesService.h


#import <Foundation/Foundation.h>
#import "QMBaseService.h"

@interface QMMessagesService : QMBaseService

@property (strong, nonatomic) NSDictionary *pushNotification;
@property (strong, nonatomic) NSMutableDictionary *messageDeliveryBlockList;
@property (strong, nonatomic) QBUUser *currentUser;

- (void)chat:(void(^)(QBChat *chat))chatBlock;
- (void)loginChat:(QBChatResultBlock)block;
- (void)logoutChat;

- (NSArray *)messageHistoryWithDialogID:(NSString *)dialogID;
- (void)addMessageToHistory:(QBChatMessage *)message withDialogID:(NSString *)dialogID;
- (void)deleteMessageHistoryWithChatDialogID:(NSString *)dialogID;

/**
 Send message
 
 @param message QBChatMessage structure which contains message text and recipient id
 @return YES if the request was sent successfully. If not - see log.
 */
- (void)sendPrivateMessage:(QBChatMessage *)message toDialog:(QBChatDialog *)dialog persistent:(BOOL)persistent completion:(void(^)(NSError *error))completion;

/**
 Send chat message to room
 
 @param message Message body
 @param room Room to send message
 @return YES if the request was sent successfully. If not - see log.
 */
- (void)sendGroupChatMessage:(QBChatMessage *)message toDialog:(QBChatDialog *)dialog completion:(void(^)(NSError *))completion;

/**
 *
 */
- (void)messagesWithDialogID:(NSString *)dialogID completion:(QBChatHistoryMessageResultBlock)completion;

@end
