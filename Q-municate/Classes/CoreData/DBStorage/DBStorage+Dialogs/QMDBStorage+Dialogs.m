//
//  QMDBStorage+Dialogs.m


#import "QMDBStorage+Dialogs.h"
#import "ModelIncludes.h"
#import "QMDBStorage+Messages.h"

@implementation QMDBStorage (Dialogs)

- (void)addQBChatMessagesInDialog:(id)dialog {
    
}

- (void)cacheQBDialogs:(NSArray *)dialogs finish:(QMDBFinishBlock)finish {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        
        [weakSelf mergeQBChatDialogs:dialogs inContext:context finish:finish];
        
    }];
}

- (void)cachedQBChatDialogs:(QMDBCollectionBlock)qbDialogs {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *context) {
        NSArray *allDialogs = [weakSelf allQBChatDialogsInContext:context];
        DO_AT_MAIN(qbDialogs(allDialogs));
    }];
}

- (NSArray *)allQBChatDialogsInContext:(NSManagedObjectContext *)context {
    
    NSArray *cdChatDialogs = [CDDialog MR_findAllInContext:context];
    NSArray *result = (cdChatDialogs.count == 0) ? @[] : [self qbChatDialogsWithcdDialogs:cdChatDialogs];
    
    return result;
}

- (NSArray *)qbChatDialogsWithcdDialogs:(NSArray *)cdDialogs {
    
    NSMutableArray *qbChatDialogs = [NSMutableArray arrayWithCapacity:cdDialogs.count];
    
    for (CDDialog *dialog in cdDialogs) {
        QBChatDialog *qbUser = [dialog toQBChatDialog];
        [qbChatDialogs addObject:qbUser];
    }
    
    return qbChatDialogs;
}

- (void)mergeQBChatDialogs:(NSArray *)qbChatDialogs inContext:(NSManagedObjectContext *)context finish:(QMDBFinishBlock)finish {
    
    NSArray *allDialogs = [self allQBChatDialogsInContext:context];
    
    NSMutableArray *toInsert = [NSMutableArray array];
    NSMutableArray *toUpdate = [NSMutableArray array];
    NSMutableArray *toDelete = [NSMutableArray arrayWithArray:allDialogs];
    
    //Update/Insert/Delete
    
    for (QBChatDialog *dialog in qbChatDialogs) {
        
        NSInteger idx = [allDialogs indexOfObject:dialog];
        
        if (idx == NSNotFound) {
            
            QBChatDialog *dialogToUpdate = nil;
            
            for (QBChatDialog *candidateToUpdate in allDialogs) {
                
                if (candidateToUpdate.ID == dialog.ID) {
                    
                    dialogToUpdate = dialog;
                    [toDelete removeObject:candidateToUpdate];
                    
                    break;
                }
            }
            
            if (dialogToUpdate) {
                [toUpdate addObject:dialogToUpdate];
            } else {
                [toInsert addObject:dialog];
            }
            
        } else {
            [toDelete removeObject:dialog];
        }
    }
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *asyncContext) {
        
        if (toUpdate.count != 0) {
            [weakSelf updateQBChatDialogs:toUpdate inContext:asyncContext];
        }
        
        if (toInsert.count != 0) {
            [weakSelf insertQBChatDialogs:toInsert inContext:asyncContext];
        }
        
        if (toDelete.count != 0) {
            [weakSelf deleteQBChatDialogs:toDelete inContext:asyncContext];
        }
        
        ILog(@"Dialogs in cahce %d", allDialogs.count);
        ILog(@"Dialogs to insert %d", toInsert.count);
        ILog(@"Dialogs to update %d", toUpdate.count);
        ILog(@"Dialogs to delete %d", toDelete.count);
        
        [weakSelf save:finish];
    }];
}

- (void)insertQBChatDialogs:(NSArray *)qbChatDialogs inContext:(NSManagedObjectContext *)context {
    
    for (QBChatDialog *qbChatDialog in qbChatDialogs) {
        CDDialog *dialogToInsert = [CDDialog MR_createEntityInContext:context];
        [dialogToInsert updateWithQBChatDialog:qbChatDialog];
    }
}

- (void)deleteQBChatDialogs:(NSArray *)qbChatDialogs inContext:(NSManagedObjectContext *)context {
    
    
    for (QBChatDialog *qbChatDialog in qbChatDialogs) {
        CDDialog *dialogToDelete = [CDDialog MR_findFirstWithPredicate:IS(@"uniqueId", qbChatDialog.ID)
                                                             inContext:context];
        [dialogToDelete MR_deleteEntityInContext:context];
    }
}

- (void)updateQBChatDialogs:(NSArray *)qbChatDialogs inContext:(NSManagedObjectContext *)context {
    
    for (QBChatDialog *qbChatDialog in qbChatDialogs) {
        CDDialog *dialogToUpdate = [CDDialog MR_findFirstWithPredicate:IS(@"uniqueId", qbChatDialog.ID)
                                                             inContext:context];
        [dialogToUpdate updateWithQBChatDialog:qbChatDialog];
    }
}


@end
