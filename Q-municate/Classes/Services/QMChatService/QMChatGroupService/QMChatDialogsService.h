//
//  QMChatGroupService.h

#import <Foundation/Foundation.h>
#import "QMBaseService.h"

@interface QMChatDialogsService : QMBaseService

- (void)fetchAllDialogs:(QBDialogsPagedResultBlock)completion;
- (void)fetchDialogsWithLastActivityFromDate:(NSDate *)date completion:(QBDialogsPagedResultBlock)completionBlock;
- (void)fetchDialogWithID:(NSString *)dialogID completion:(void (^)(QBChatDialog *dialog))block;
- (void)fetchDialogsWithIDs:(NSArray *)dialogIDs completion:(QBDialogsPagedResultBlock)completion;

- (void)createChatDialog:(QBChatDialog *)chatDialog completion:(QBChatDialogResultBlock)completion;

- (void)createPrivateChatDialogIfNeededWithOpponent:(QBUUser *)opponent completion:(void(^)(QBChatDialog *chatDialog))completion;
- (void)createPrivateDialogIfNeededWithNotification:(QBChatMessage *)notification completion:(void(^)(QBChatDialog *chatDialog))completion;
- (void)createGroupChatDialog:(QBChatDialog *)chatDialog completion:(void(^)(QBChatDialog *chatDialog))block;

- (void)updateChatDialogWithID:(NSString *)dialogID extendedRequest:(NSMutableDictionary *)extendedRequest completion:(QBChatDialogResultBlock)completion;

- (void)updateOrCreateDialogWithMessage:(QBChatMessage *)message isMine:(BOOL)isMine;

- (NSArray *)dialogHistory;
- (void)addDialogToHistory:(QBChatDialog *)chatDialog;
- (void)addDialogs:(NSArray *)dialogs;

- (QBChatDialog *)privateDialogWithOpponentID:(NSUInteger)opponentID;
- (QBChatDialog *)chatDialogWithID:(NSString *)dialogID;

- (void)deleteLocalDialog:(QBChatDialog *)dialog;
- (void)deleteChatDialog:(QBChatDialog *)dialog completion:(void(^)(BOOL success))completionHanlder;

- (void)leaveFromRooms;
- (void)joinRooms;

@end
