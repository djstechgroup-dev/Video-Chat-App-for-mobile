//
//  QMDBStorage+Users.m


#import "QMDBStorage+Users.h"
#import "ModelIncludes.h"

@interface QMDBStorage ()

<NSFetchedResultsControllerDelegate>

@end

@implementation QMDBStorage (Users)

#pragma mark - Public methods

- (void)cachedQbUsers:(QMDBCollectionBlock)qbUsers {
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *context) {
        
        NSArray *allUsers = [weakSelf allUsersInContext:context];
        DO_AT_MAIN(qbUsers(allUsers));
        
    }];
}

- (void)cacheUsers:(NSArray *)users finish:(QMDBFinishBlock)finish {
    
    __weak __typeof(self)weakSelf = self;
    
    [self async:^(NSManagedObjectContext *context) {
        [weakSelf mergeQBUsers:users inContext:context finish:finish];
    }];
}

#pragma mark - Private methods

- (NSArray *)allUsersInContext:(NSManagedObjectContext *)context {
    
    NSArray *cdUsers = [CDUser MR_findAllInContext:context];
    NSArray *result = (cdUsers.count == 0) ? @[] : [self qbUsersWithcdUsers:cdUsers];
    
    return result;
}

- (NSArray *)qbUsersWithcdUsers:(NSArray *)cdUsers {
    
    NSMutableArray *qbUsers = [NSMutableArray arrayWithCapacity:cdUsers.count];
    
    for (CDUser *user in cdUsers) {
        QBUUser *qbUser = [user toQBUUser];
        [qbUsers addObject:qbUser];
    }
    
    return qbUsers;
}

#define TEST_DUPLICATE_CASE

#ifdef TEST_DUPLICATE_CASE

- (void)checkDuplicateInQBUsers:(NSArray *)qbUsers {
    
    NSMutableSet *ids = [NSMutableSet set];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(QBUUser *qbUser, NSDictionary *bindings) {
        
        NSNumber *userId = @(qbUser.ID);
        BOOL contains = [ids containsObject:userId];
        
        if (!contains) {
            [ids addObject:userId];
        }
        return contains;
    }];
    
    //TODO: Need add version checker
    __unused NSArray *duplicates = [qbUsers filteredArrayUsingPredicate:predicate];
    NSAssert(duplicates.count == 0, @"Collection has duplicates");
}

#endif

- (void)mergeQBUsers:(NSArray *)qbUsers inContext:(NSManagedObjectContext *)context finish:(QMDBFinishBlock)finish {
    
#ifdef TEST_DUPLICATE_CASE
    [self checkDuplicateInQBUsers:qbUsers];
#endif
    
    NSArray *allQBUsersInCache = [self allUsersInContext:context];
    
    NSMutableArray *toInsert = [NSMutableArray array];
    NSMutableArray *toUpdate = [NSMutableArray array];
    NSMutableArray *toDelete = [NSMutableArray arrayWithArray:allQBUsersInCache];
    
    //Update/Insert/Delete
    
    for (QBUUser *user in qbUsers) {
        
        NSInteger idx = [allQBUsersInCache indexOfObject:user];
        
        if (idx == NSNotFound) {
            
            QBUUser *toUpdateUser = nil;
            
            for (QBUUser *candidateToUpdate in allQBUsersInCache) {
                
                if (candidateToUpdate.ID == user.ID) {
                    
                    toUpdateUser = user;
                    [toDelete removeObject:candidateToUpdate];
                    
                    break;
                }
            }
            
            if (toUpdateUser) {
                [toUpdate addObject:toUpdateUser];
            } else {
                [toInsert addObject:user];
            }
            
        } else {
            [toDelete removeObject:user];
        }
    }
    
    __weak __typeof(self)weakSelf = self;
    [self async:^(NSManagedObjectContext *asyncContext) {
        
        if (toUpdate.count != 0) {
            [weakSelf updateQBUsers:toUpdate inContext:asyncContext];
        }
        
        if (toInsert.count != 0) {
            [weakSelf insertQBUsers:toInsert inContext:asyncContext];
        }
        
        if (toDelete.count != 0) {
            [weakSelf deleteQBUsers:toDelete inContext:asyncContext];
        }
        
        ILog(@"Users in cahce %d", allQBUsersInCache.count);
        ILog(@"Users to insert %d", toInsert.count);
        ILog(@"Users to update %d", toUpdate.count);
        ILog(@"Users to delete %d", toDelete.count);
        
        [weakSelf save:finish];
    }];
}

- (void)insertQBUsers:(NSArray *)qbUsers inContext:(NSManagedObjectContext *)context {
    
    for (QBUUser *qbUser in qbUsers) {
        CDUser *user = [CDUser MR_createEntityInContext:context];
        [user updateWithQBUser:qbUser];
    }
}

- (void)deleteQBUsers:(NSArray *)qbUsers inContext:(NSManagedObjectContext *)context {
    
    
    for (QBUUser *qbUser in qbUsers) {
        CDUser *userToDelete = [CDUser MR_findFirstWithPredicate:IS(@"uniqueId", @(qbUser.ID))
                                                       inContext:context];
        [userToDelete MR_deleteEntityInContext:context];
    }
}

- (void)updateQBUsers:(NSArray *)qbUsers inContext:(NSManagedObjectContext *)context {
    
    for (QBUUser *qbUser in qbUsers) {
        CDUser *userToUpdate = [CDUser MR_findFirstWithPredicate:IS(@"uniqueId", @(qbUser.ID))
                                                       inContext:context];
        [userToUpdate updateWithQBUser:qbUser];
    }
}

@end