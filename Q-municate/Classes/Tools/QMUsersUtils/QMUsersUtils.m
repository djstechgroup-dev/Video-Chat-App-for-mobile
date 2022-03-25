//
//  QMUsersUtils.m


#import "QMUsersUtils.h"

@implementation QMUsersUtils


+ (NSArray *)sortUsersByFullname:(NSArray *)users
{    
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc]
                                initWithKey:@"fullName"
                                ascending:YES
                                selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedUsers = [users sortedArrayUsingDescriptors:@[sorter]];
    
    return sortedUsers;
}

+ (NSMutableArray *)filteredUsers:(NSArray *)users withFlterArray:(NSArray *)usersToFilter
{
    NSMutableArray *filteredUsrs = users.mutableCopy;
    for (QBUUser *usr in users) {
        for (QBUUser *filterUsr in usersToFilter) {
            if (filterUsr.ID == usr.ID) {
                [filteredUsrs removeObject:usr];
            }
        }
    }
    return filteredUsrs;
}

+ (NSURL *)userAvatarURL:(QBUUser *)user {
    NSURL *url = nil;
#warning Old avatar url logic changed!
    if (user.avatarURL) {
        url = [NSURL URLWithString:user.avatarURL];
    } else {
        url = [NSURL URLWithString:user.website];
    }
    return url;
}

@end
