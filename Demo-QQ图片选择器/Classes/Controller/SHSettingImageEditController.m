//
//  SNPMDaoDaoPersonImageEditController.m
//  SuningEBuy
//
//  Created by Suning on 15/10/29.
//  Copyright (c) 2015年 Suning. All rights reserved.
//

#import "SHSettingImageEditController.h"
#import "ViewController.h"
#import "UIView+Frame.h"
#import <objc/runtime.h>

#define kScreenWidth    [UIScreen mainScreen].bounds.size.width
#define kScreenHeight   [UIScreen mainScreen].bounds.size.height
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define DaoDaoPurpleTextColor UIColorFromRGB(0x574ba6)

//16进制色值参数转换
#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface UIView(ClippingBox)
@property (nonatomic,copy) dispatch_block_t maskBlock;
@end
@implementation UIView(ClippingBox)
-(dispatch_block_t)maskBlock{
    return (dispatch_block_t)objc_getAssociatedObject(self, "maskBlock");
}

-(void)setMaskBlock:(dispatch_block_t)block{
    objc_setAssociatedObject(self, "maskBlock", block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end


@interface SNPMDaoDaoPersonScrollView : UIScrollView<UIGestureRecognizerDelegate>{
    BOOL boxTriggered;
    CGFloat startY;
}

@end
@implementation SNPMDaoDaoPersonScrollView

-(id)init{
    if (self = [super init]) {
        self.panGestureRecognizer.delegate = self;
        self.pinchGestureRecognizer.delegate = self;
    }
    return self;
}

//在触及clippingBox周边时，不触发scrollView手势，而是拖动clippingBox。
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    CGPoint point = [touch locationInView:self];
    startY = point.y-self.contentOffset.y;
    UIView *box = [self.superview viewWithTag:3];
    CGFloat boxY0 = box.frame.origin.y;
    CGFloat boxY1 = box.frame.origin.y+box.frame.size.height;
    if (fabs(startY-boxY0)<40 || fabs(startY-boxY1)<40 || (self.contentOffset.y<=0 && self.zoomScale == 1 && startY>(boxY0-40) && startY<(boxY1+40))) {
        if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
            boxTriggered = YES;
            return NO;
        }
        if ([gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
            return YES;
        } else {
            return NO;
        }
    }else{
        boxTriggered = NO;
        return YES;
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if (boxTriggered) {
        UIView *box = [self.superview viewWithTag:3];
        static CGFloat lastY;
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        CGFloat distance;
        if (startY>0) {
            distance = startY - (point.y-self.contentOffset.y);
            startY = -1000;
        }else{
            distance = lastY - (point.y-self.contentOffset.y);
        }
        lastY = point.y-self.contentOffset.y;
        CGRect frame = box.frame;
        frame.origin.y = frame.origin.y - distance;
        //确保clippingBox不会滑出屏幕
        if (frame.origin.y<=5) {
            frame.origin.y = 5;
        }
        if (frame.origin.y>(self.frame.size.height-kScreenWidth-5)) {
            frame.origin.y = self.frame.size.height-kScreenWidth-5;
        }
        box.frame = frame;
        if (nil!=box.maskBlock) {
            box.maskBlock();
        }
    }else{
        [super touchesMoved:touches withEvent:event];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    boxTriggered = NO;
}
@end

@interface SHSettingImageEditController ()<UIScrollViewDelegate>{
    CGPoint _offset;
    CGFloat _scale;
    CGRect _rect;
    
    NSDictionary *cutPos;           //裁剪尺寸
    CGFloat      orginalScale;      //原始图片缩放比例
}
@property (nonatomic,strong) UIImage      *orignalImage;
/** 要裁剪的图片所在背景 */
@property (nonatomic,strong) UIView       *iView;
@property (nonatomic,strong) UIView       *floatingView;
@property (nonatomic,strong) UIView       *clippingBoxView;
/** 底部选取按钮 */
@property (nonatomic,strong) UIButton  *chooseImgBtn;
/** 底部取消按钮 */
@property (nonatomic,strong) UIButton  *cancelImgBtn;

@property (nonatomic,strong) SNPMDaoDaoPersonScrollView *editScrollView;
@property (nonatomic,strong) UIImageView  *editImageView;
@end

@implementation SHSettingImageEditController

- (id)initWithImage:(UIImage *)image{
//    if (self = [super init]) {
//    }
    self.orignalImage = image;
    return self;
}

- (UIView *)iView {
    if (nil == _iView) {
        CGSize sz = self.view.frame.size;
        CGFloat navHeight = 64.0f;
        _iView = [[UIView alloc] initWithFrame:CGRectMake(.0f,40.0f,sz.width,sz.height-navHeight-50)];
        _iView.backgroundColor = [UIColor blackColor];
    }
    return _iView;
}

//橘色框所在view，用来选中图片裁减区域
- (UIView *)clippingBoxView {
    if (nil == _clippingBoxView) {
        _clippingBoxView = [[UIView alloc] init];
        _clippingBoxView.layer.borderWidth = 2.0f;
        _clippingBoxView.layer.borderColor = DaoDaoPurpleTextColor.CGColor;
        _clippingBoxView.userInteractionEnabled = NO;
        CGSize sz = self.iView.frame.size;
        CGFloat y = (sz.height-sz.width)/2.;
        _clippingBoxView.frame = CGRectMake(.0f,y,sz.width,sz.width);
    }
    return _clippingBoxView;
}

//盖在imageView上，用于实现默认的半透明（alpha=0.5）效果。是未裁剪的部分
- (UIView *)floatingView {
    if (nil == _floatingView) {
        _floatingView = [[UIView alloc] init];
        _floatingView.backgroundColor = RGBACOLOR(0,0,0,0.5);
        _floatingView.userInteractionEnabled = NO;
        CGSize sz = self.iView.frame.size;
        _floatingView.frame = CGRectMake(.0f,.0f,sz.width,sz.height);
    }
    return _floatingView;
}

- (UIScrollView *)editScrollView {
    if (nil == _editScrollView) {
        _editScrollView = [[SNPMDaoDaoPersonScrollView alloc] init];
        CGSize sz = self.iView.frame.size;
        _editScrollView.frame = CGRectMake(.0f,.0f,sz.width,sz.height);
        _editScrollView.contentSize = CGSizeMake(MAX(_editScrollView.frame.size.width, _orignalImage.size.width),MAX(_editScrollView.frame.size.height, _orignalImage.size.height));
        _editScrollView.maximumZoomScale = 4;
        _editScrollView.bounces = NO;
        _editScrollView.delegate = self;
    }
    return _editScrollView;
}

- (UIImageView *)editImageView {
    if (nil == _editImageView) {
        _editImageView = [[UIImageView alloc] initWithImage:_orignalImage];
        
        if (_editScrollView.frame.size.width>_orignalImage.size.width) {
            //图片宽度小于scrollView宽度，则置于scrollView宽度中间位置
            [_editImageView setCenter:CGPointMake(_editScrollView.frame.size.width/2., _editScrollView.frame.size.height/2.)];
        }
    }
    return _editImageView;
}


-(UIButton *)chooseImgBtn{
    CGFloat chooseImgBtnW = 50;
    CGFloat chooseBtnH = 35;
    CGFloat chooseBtnY = kScreenHeight - chooseBtnH - 22;
    if (!_chooseImgBtn) {
        _chooseImgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _chooseImgBtn.frame = CGRectMake(kScreenWidth-chooseImgBtnW-14 , chooseBtnY, chooseImgBtnW, chooseBtnH);
        [_chooseImgBtn setTitle:@"使用" forState:UIControlStateNormal];
        //颜色待修正
        [_chooseImgBtn setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
//        [_chooseImgBtn setTitleColor:[UIColor colorWithHexString:@"#ffffff"] forState:UIControlStateNormal];
        _chooseImgBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
        [_chooseImgBtn addTarget:self action:@selector(clickTheChooseImgBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chooseImgBtn;
}

-(UIButton *)cancelImgBtn{
    CGFloat chooseImgBtnW = 50;
    CGFloat chooseBtnH = 35;
    CGFloat chooseBtnY = kScreenHeight - chooseBtnH - 22;
    if (!_cancelImgBtn) {
        _cancelImgBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelImgBtn.frame = CGRectMake(14, chooseBtnY, chooseImgBtnW, chooseBtnH);
        [_cancelImgBtn setTitle:@"放弃" forState:UIControlStateNormal];
        //颜色待修正
        [_cancelImgBtn setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
//        [_cancelImgBtn setTitleColor:[UIColor colorWithHexString:@"#ffffff"] forState:UIControlStateNormal];
        _cancelImgBtn.titleLabel.font = [UIFont systemFontOfSize:17.0];
        [_cancelImgBtn addTarget:self action:@selector(clickTheCancleBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelImgBtn;
}

-(void)clickTheChooseImgBtn{
    
    //获取有效内容区域百分比
    [self scrollViewDidScroll:_editScrollView];
    CGFloat boxTop = _clippingBoxView.frame.origin.y;
    CGFloat boxBtm = boxTop + kScreenWidth;
    
    CGFloat coveredTop,coveredBtm,coveredRgt,coveredLft;
    
    if (_offset.y>0) {
        coveredTop = 0;
        coveredBtm = boxBtm-boxTop;
    }else{
        if (_editImageView.origin.y<boxTop) {
            coveredTop = 0;
        }else{
            coveredTop = _editImageView.origin.y - boxTop;
        }
        if ((_editImageView.origin.y+_editImageView.height)>boxBtm) {
            coveredBtm = boxBtm-boxTop;
        }else{
            coveredBtm = _editImageView.origin.y+_editImageView.height-boxTop;
        }
    }
    
    if (_offset.x>0) {
        coveredLft = 0;
        coveredRgt = kScreenWidth;
    }else{
        coveredLft = _editImageView.origin.x;
        coveredRgt = _editImageView.origin.x + _editImageView.width;
    }
    
    //计算手势放大缩小比例，还原坐标by:YDQ
    int startX,startY,cutWidth,cutHeight;
    CGFloat calScale = _editScrollView.zoomScale*orginalScale;
    startX = _offset.x*[UIScreen mainScreen].scale/calScale;
    
    if (_offset.y>0) {
        startY = (_offset.y*[UIScreen mainScreen].scale+_clippingBoxView.frame.origin.y*[UIScreen mainScreen].scale)/calScale;
    }
    else{
        startY = 0;
        if (_clippingBoxView.frame.origin.y*[UIScreen mainScreen].scale>(_editImageView.frame.origin.y*[UIScreen mainScreen].scale-(_editScrollView.contentSize.height*[UIScreen mainScreen].scale-_editImageView.frame.size.height*[UIScreen mainScreen].scale)/2)) {
            startY = ((_editScrollView.contentSize.height*[UIScreen mainScreen].scale-_editImageView.frame.size.height*[UIScreen mainScreen].scale)/2+_clippingBoxView.frame.origin.y*[UIScreen mainScreen].scale-_editImageView.frame.origin.y*[UIScreen mainScreen].scale)/calScale;
        }
    }
    
    cutWidth = kScreenWidth*[UIScreen mainScreen].scale/calScale;
    cutHeight = kScreenWidth*[UIScreen mainScreen].scale/calScale;
    
    cutPos = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%d",startX],@"startX",[NSString stringWithFormat:@"%d",startY],@"startY",[NSString stringWithFormat:@"%d",cutWidth],@"width",[NSString stringWithFormat:@"%d",cutHeight],@"height", nil];
    
    NSDictionary* drawInfo;
    if (_offset.x>0 && _offset.y>0) {
        drawInfo = nil;
    }else{
        drawInfo = @{@"top":[NSNumber numberWithFloat:coveredTop/kScreenWidth],
                     @"bottom":[NSNumber numberWithFloat:coveredBtm/kScreenWidth],
                     @"left":[NSNumber numberWithFloat:coveredLft/kScreenWidth],
                     @"right":[NSNumber numberWithFloat:coveredRgt/kScreenWidth]
                     };
    }
    
    //强制刷新scrollView待裁剪区域，当需要从未来pushed页面返回时。
    [self scrollViewDidScroll:_editScrollView];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(self.clippingBoxView.frame.size.width, self.clippingBoxView.frame.size.height), NO, [UIScreen mainScreen].scale);
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), -(_offset.x+self.clippingBoxView.frame.origin.x), -(_offset.y+self.clippingBoxView.frame.origin.y));
    [_editScrollView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if (_delegate && [_delegate respondsToSelector:@selector(chooseThePersonImage:)]) {
        [_delegate chooseThePersonImage:outImage];
    }
}

#pragma mark - 取消事件
-(void)clickTheCancleBtn{
    [self.navigationController popViewControllerAnimated:YES];
//    [self dismissViewControllerAnimated:YES completion:nil];
}

//为floatingView的layer加mask，mask遮住部分保留该view的原色，未遮住部分显示floatingView的superView的对应区域颜色
-(void)setClippingMask{
    CGSize sz = self.iView.frame.size;
    CGFloat x = self.clippingBoxView.frame.origin.x;
    CGFloat y = self.clippingBoxView.frame.origin.y;
    CGFloat w = self.clippingBoxView.frame.size.width;
    CGFloat h = self.clippingBoxView.frame.size.height;
    CAShapeLayer* maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = _floatingView.frame;
    CGMutablePathRef maskPath = CGPathCreateMutable();
    CGPathMoveToPoint(maskPath, NULL, _floatingView.origin.x, _floatingView.origin.y); //0
    CGPathAddLineToPoint(maskPath, NULL, sz.width, 0); //1
    CGPathAddLineToPoint(maskPath, NULL, sz.width, sz.height); //2
    CGPathAddLineToPoint(maskPath, NULL, 0, sz.height); //3
    CGPathAddLineToPoint(maskPath, NULL, 0, y+h); //4
    CGPathAddLineToPoint(maskPath, NULL, x+w, y+h); //5
    CGPathAddLineToPoint(maskPath, NULL, x+w, y); //6
    CGPathAddLineToPoint(maskPath, NULL, x, y); //7
    CGPathAddLineToPoint(maskPath, NULL, x, y+h); //8
    CGPathAddLineToPoint(maskPath, NULL, 0, y+h); //9
    CGPathAddLineToPoint(maskPath, NULL, 0, 0); //10
    maskLayer.path = maskPath;
    CGPathRelease(maskPath);
    _floatingView.layer.mask = maskLayer;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    /*
     第一层为承载editImageView的ScrollView
     第二层为阴影版，以第三层clippingBoxView为mask，使得mask覆盖到区域，无阴影效果，露出第一层image底色
     第三层clippingBoxView，为第二层提供mask之path，同时绘制橘红色相框。
     */
    [self.editScrollView addSubview:self.editImageView];
    [self.iView addSubview:self.editScrollView];
    [self.iView addSubview:self.floatingView];
    [self setClippingMask];
    [self.iView addSubview:self.clippingBoxView];
    _clippingBoxView.tag = 3;
    __weak __typeof(self)weakSelf = self;
    _clippingBoxView.maskBlock = ^{
        [weakSelf setClippingMask];
    };
    [self.view addSubview:self.iView];
    [self.view addSubview:self.chooseImgBtn];
    [self.view addSubview:self.cancelImgBtn];
    
    self.editImageView.image = self.orignalImage;
    [self refreshImageView];
    
    orginalScale = [self calOrginalScale];
    self.view.backgroundColor = [UIColor blackColor];

#pragma mark    发送通知
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SHSettingImageEditNotification" object:@{@"vc" : self}];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

//计算刚进入页面，图片放到容器里的比例
- (CGFloat)calOrginalScale{
    return MIN(_editImageView.frame.size.width*[UIScreen mainScreen].scale/_orignalImage.size.width, _editImageView.frame.size.height*[UIScreen mainScreen].scale/_orignalImage.size.height);
}

/** 取消 */
-(void)righBarClick{
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGFloat)calScaleFactor{
    CGFloat scaleX = _editScrollView.contentSize.width/_editImageView.frame.size.width;
    CGFloat scaleY = _editScrollView.contentSize.height/_editImageView.frame.size.height;
    
    return scaleX<scaleY?scaleX:scaleY;
}

#pragma mark- 校准放大后位置为居中
- (void)resetImageViewFrame
{
    CGSize size = (_editImageView.image) ? _editImageView.image.size : _editImageView.frame.size;
    if(size.width>0 && size.height>0){
        CGFloat ratio = MIN(_editScrollView.frame.size.width / size.width, _editScrollView.frame.size.height / size.height);
        CGFloat W = ratio * size.width * _editScrollView.zoomScale;
        CGFloat H = ratio * size.height * _editScrollView.zoomScale;
        _editImageView.frame = CGRectMake(MAX(0, (_editScrollView.width-W)/2.), MAX(0, (_editScrollView.height-H)/2.), W, H);
    }
}

- (void)resetZoomScaleWithAnimated:(BOOL)animated
{
    _editScrollView.contentSize = _editImageView.frame.size;
    _editScrollView.minimumZoomScale = 1;
    [_editScrollView setZoomScale:_editScrollView.minimumZoomScale animated:animated];
}

-(void)refreshImageView
{
    _editImageView.image = _orignalImage;
    [self resetImageViewFrame];
    [self resetZoomScaleWithAnimated:NO];
}

#pragma mark- ScrollView delegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.editImageView;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    _scale = scrollView.zoomScale;
    _offset = scrollView.contentOffset;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    _offset.x = (_editScrollView.bounds.size.width > _editScrollView.contentSize.width)?
    (_editScrollView.bounds.size.width - _editScrollView.contentSize.width) * 0.5 : 0.0;
    _offset.y = (_editScrollView.bounds.size.height > _editScrollView.contentSize.height)?
    (_editScrollView.bounds.size.height - _editScrollView.contentSize.height) * 0.5 : 0.0;
    //确保zoom的放大中心点位于屏幕中心
    _editImageView.center = CGPointMake(_editScrollView.contentSize.width*0.5 + _offset.x,_editScrollView.contentSize.height*0.5 + _offset.y);
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

-(void)chooseTheImg:(UIImage*)img{
    if (_delegate && [_delegate respondsToSelector:@selector(chooseTheImg:)]) {
        [_delegate chooseThePersonImage:img];
    }
}

-(void)chooseTheImg:(UIImage*)img orginal:(UIImage*)orginalImg{
    if (_delegate && [_delegate respondsToSelector:@selector(chooseThePersonImage:orginal:cutPos:)]) {
        [_delegate chooseThePersonImage:img orginal:orginalImg cutPos:cutPos];
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
