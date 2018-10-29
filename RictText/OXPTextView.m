//
//  OXPTextView.m
//
//  Created by oxape on 2018/8/11.
//

#import "OXPTextView.h"
#import <CoreText/CoreText.h>

@interface OXPTextView()

@property (nonatomic, assign, readwrite) CGFloat fitHeight;
@property (nonatomic, copy, readwrite) NSArray<OXPTextString *> *strings;
@property (nonatomic, assign) BOOL invalidHeight;
@property (nonatomic, assign) CTFrameRef ctFrame;
@end

@implementation OXPTextView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _invalidHeight = YES;
        self.backgroundColor = [UIColor whiteColor];
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
        [self addGestureRecognizer:tapGestureRecognizer];
        
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
        longPressGestureRecognizer.minimumPressDuration = 1.0;
        [self addGestureRecognizer:longPressGestureRecognizer];
        
        [tapGestureRecognizer requireGestureRecognizerToFail:longPressGestureRecognizer];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    // 步骤 1
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 步骤 2
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    // 步骤 3
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    // 步骤 4
    NSMutableAttributedString *attString = [NSMutableAttributedString new];
    for (OXPTextString *string in self.strings) {
        [attString appendAttributedString:string.attributedString];
    }
    CTFramesetterRef framesetter =
    CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    CTFrameRef frame =
    CTFramesetterCreateFrame(framesetter,
                             CFRangeMake(0, [attString length]), path, NULL);
    self.ctFrame = frame;
    // 步骤 5
    CTFrameDraw(frame, context);
    // 步骤 6
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
}

- (void)layoutSubviews {
    OXPLogInfo(@"layoutSubviews frame = %@", NSStringFromCGRect(self.frame));
    return [super layoutSubviews];
}

- (CGSize)intrinsicContentSize {
    OXPLogInfo(@"intrinsicContentSize frame = %@", NSStringFromCGRect(self.frame));
    return [super intrinsicContentSize];
}

- (void)tapGesture:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self];
    CFIndex index = [self touchContentOffsetInView:self atPoint:point];
    if (index < 0) {
        return;
    }
    NSUInteger start = 0;
    for (OXPTextString *string in self.strings) {
        if (!string.clickable) {
            continue;
        }
        NSRange range = NSMakeRange(start, string.attributedString.length);
        if (NSLocationInRange(index, range)) {
            if ([self.delegate respondsToSelector:@selector(textView:touchString:)]) {
                [self.delegate textView:self touchString:string];
            }
            break;
        }
        start += string.attributedString.length;
    }
}

- (void)longPressGesture:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [recognizer locationInView:self];
        CFIndex index = [self touchContentOffsetInView:self atPoint:point];
        if (index < 0) {
            return;
        }
        NSUInteger start = 0;
        for (OXPTextString *string in self.strings) {
            if (!string.clickable) {
                continue;
            }
            NSRange range = NSMakeRange(start, string.attributedString.length);
            if (NSLocationInRange(index, range)) {
                if ([self.delegate respondsToSelector:@selector(textView:touchString:)]) {
                    [self.delegate textView:self longTouchString:string];
                }
                break;
            }
            start += string.attributedString.length;
        }
    }
}

- (CGFloat)fitHeight {
    if (!self.invalidHeight) {
        return _fitHeight;
    }
    self.invalidHeight = NO;
    NSMutableAttributedString *attString = [NSMutableAttributedString new];
    for (OXPTextString *string in self.strings) {
        [attString appendAttributedString:string.attributedString];
    }
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, self.requiredWidth, CGFLOAT_MAX));
    // 创建CTFramesetterRef实例
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    
    // 获得要缓制的区域的高度
    CGSize restrictSize = CGSizeMake(self.requiredWidth, CGFLOAT_MAX);
    CGSize coreTextSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), nil, restrictSize, nil);
    _fitHeight = coreTextSize.height;
    return _fitHeight;
}

// 将点击的位置转换成字符串的偏移量，如果没有找到，则返回-1
- (CFIndex)touchContentOffsetInView:(UIView *)view atPoint:(CGPoint)point {
    CTFrameRef textFrame = self.ctFrame;
    CFArrayRef lines = CTFrameGetLines(textFrame);
    if (!lines) {
        return -1;
    }
    CFIndex count = CFArrayGetCount(lines);
    
    // 获得每一行的origin坐标
    CGPoint origins[count];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0,0), origins);
    
    // 翻转坐标系
    CGAffineTransform transform =  CGAffineTransformMakeTranslation(0, view.bounds.size.height);
    transform = CGAffineTransformScale(transform, 1.f, -1.f);
    
    CFIndex idx = -1;
    for (int i = 0; i < count; i++) {
        CGPoint linePoint = origins[i];
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        // 获得每一行的CGRect信息
        CGRect flippedRect = [self getLineBounds:line point:linePoint];
        CGRect rect = CGRectApplyAffineTransform(flippedRect, transform);
        
        if (CGRectContainsPoint(rect, point)) {
            // 将点击的坐标转换成相对于当前行的坐标
            CGPoint relativePoint = CGPointMake(point.x-CGRectGetMinX(rect),
                                                point.y-CGRectGetMinY(rect));
            // 获得当前点击坐标对应的字符串偏移
            idx = CTLineGetStringIndexForPosition(line, relativePoint);
        }
    }
    return idx;
}

- (CGRect)getLineBounds:(CTLineRef)line point:(CGPoint)point {
    CGFloat ascent = 0.0f;
    CGFloat descent = 0.0f;
    CGFloat leading = 0.0f;
    CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CGFloat height = ascent + descent;
    return CGRectMake(point.x, point.y - descent, width, height);
}

- (void)setStrings:(NSArray<OXPTextString *> *)strings {
    _strings = strings;
    self.invalidHeight = YES;
    [self setNeedsDisplay];
}

- (void)setCtFrame:(CTFrameRef)ctFrame {
    if (_ctFrame != ctFrame) {
        if (_ctFrame != nil) {
            CFRelease(_ctFrame);
        }
        CFRetain(ctFrame);
        _ctFrame = ctFrame;
    }
}

@end
