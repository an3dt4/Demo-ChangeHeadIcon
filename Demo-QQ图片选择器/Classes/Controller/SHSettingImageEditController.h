//
//  SNPMDaoDaoPersonImageEditController.h
//  SuningEBuy
//
//  Created by Suning on 15/10/29.
//  Copyright (c) 2015年 Suning. All rights reserved.
//
//  编辑图片，裁剪

#import <UIKit/UIKit.h>

@protocol SHSettingImageEditDelegate <NSObject>

@optional
- (void)chooseThePersonImage:(UIImage*)img;
- (void)chooseThePersonImage:(UIImage*)img orginal:(UIImage*)orginalImg cutPos:(NSDictionary *)posDic;

@end


@interface SHSettingImageEditController : UIViewController

@property (nonatomic,weak) id<SHSettingImageEditDelegate>delegate;

- (id)initWithImage:(UIImage *)image;

@end
