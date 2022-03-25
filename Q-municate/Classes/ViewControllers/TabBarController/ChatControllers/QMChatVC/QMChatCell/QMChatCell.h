
//
//  QMChatCell.h


#import <UIKit/UIKit.h>
#import "QMMessage.h"

@class QMMessage;
@class QMImageView;

@protocol QMChatCellDelegate <NSObject>

- (void)chatCell:(id)cell didSelectMessage:(QMMessage *)message;

@end

@interface QMChatCell : UITableViewCell

@property (strong, nonatomic, readonly) UIView *containerView;
@property (strong, nonatomic, readonly) UIView *headerView;
@property (strong, nonatomic, readonly) QMImageView *balloonImageView;
@property (strong, nonatomic, readonly) QMImageView *userImageView;
@property (strong, nonatomic, readonly) UILabel *title;
@property (strong, nonatomic, readonly) UIImageView *deliveryStatusView;
@property (strong, nonatomic, readonly) UILabel *timeLabel;

@property (weak, nonatomic) id <QMChatCellDelegate> delegate;

- (void)setMessage:(QMMessage *)message user:(QBUUser *)user isMe:(BOOL)isMe;
- (void)setBalloonImage:(UIImage *)balloonImage;
- (void)setDeliveryStatus:(NSUInteger)deliveryStatus;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)createContainerSubviews;
- (NSDateFormatter *)formatter;

@end