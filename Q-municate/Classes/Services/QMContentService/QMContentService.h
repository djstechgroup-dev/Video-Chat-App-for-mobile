//
//  QMContentService.h


#import <Foundation/Foundation.h>
#import "QMContentOperation.h"

@interface QMContentService : NSObject

- (void)uploadJPEGImage:(UIImage *)image progress:(QMContentProgressBlock)progress completion:(QMCFileUploadTaskResultBlockBlock)completion;
- (void)uploadPNGImage:(UIImage *)image progress:(QMContentProgressBlock)progress completion:(QMCFileUploadTaskResultBlockBlock)completion;

- (void)downloadFileWithUrl:(NSURL *)url completion:(void(^)(NSData *data))completion;
- (void)downloadFileWithBlobID:(NSUInteger )blobID progress:(QMContentProgressBlock)progress completion:(QMCFileDownloadTaskResultBlockBlock)completion;

@end
