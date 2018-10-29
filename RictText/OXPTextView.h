//
//  OXPTextView.h
//
//  Created by oxape on 2018/8/11.
//

#import <UIKit/UIKit.h>
#import "OXPTextString.h"

@class OXPTextView;

@protocol OXPTextViewDelegate<NSObject>

- (void)textView:(OXPTextView *)textView touchString:(OXPTextString *)string;
- (void)textView:(OXPTextView *)textView longTouchString:(OXPTextString *)string;

@end

@interface OXPTextView : UIView

@property (nonatomic, assign) CGFloat requiredWidth;
@property (nonatomic, assign, readonly) CGFloat fitHeight;

@property (nonatomic, copy, readonly) NSArray<OXPTextString *> *strings;

@property (nonatomic, weak) id<OXPTextViewDelegate> delegate;

- (void)setStrings:(NSArray<OXPTextString *> *)strings;


@end
