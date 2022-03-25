//
//  NSString+UsedSize.m


#import "NSString+UsedSize.h"

@implementation NSString (UsedSize)

- (CGSize)usedSizeForWidth:(CGFloat)width font:(UIFont *)font withAttributes:(NSDictionary *)attributes {
    
    // NSString class method: boundingRectWithSize:options:attributes:context is
    // available only on ios7.0 sdk.
    CGRect frame = [self boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX)
                                              options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                           attributes:@{NSFontAttributeName: font}
                                              context:nil];
    CGSize size = frame.size;
    size.height = ceilf(size.height) +1;
    size.width = ceilf(size.width);
    
    return size;
}

@end
