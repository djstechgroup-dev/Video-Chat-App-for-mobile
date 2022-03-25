//
//  QMUploadContentOperation.m


#import "QMUploadContentOperation.h"

@interface QMUploadContentOperation()

@property (strong, nonatomic) NSData *data;
@property (strong, nonatomic) NSString *fileName;
@property (strong, nonatomic) NSString *contentType;
@property (assign, nonatomic) BOOL public;

@end

@implementation QMUploadContentOperation

- (instancetype)initWithUploadFile:(NSData *)data
                          fileName:(NSString *)fileName
                       contentType:(NSString *)contentType
                          isPublic:(BOOL)isPublic {
    
    self = [super init];
    if (self) {
        
        self.data = data;
        self.fileName = fileName;
        self.contentType = contentType;
        self.public = isPublic;
    }
    
    return self;
}

- (void)main {
    
    self.cancelableOperation = [QBContent TUploadFile:self.data
                                             fileName:self.fileName
                                          contentType:self.contentType
                                             isPublic:self.public
                                             delegate:self];
}

@end
