//
//  RefreshControl.m
//  demo4RefreshControl
//
//  Created by Ginhoor on 13-11-20.
//  Copyright (c) 2013年 Ginhoor. All rights reserved.
//

#import "GRefreshControl.h"
#import "UIColor+Hex.h"

#define kRefreshControlHeight 300
#define kStartLoadingThreshold 80
#define kLodingHeight 5/2.0f

#define kCellWidth 71/2.0f
#define kCellNum 9

#define kRefreshArrawImageName @"RefreshArraw"



@interface ShapeCell : NSObject
@property (strong, nonatomic) CAShapeLayer *layer;
@property (assign, nonatomic) CGRect frame;
@end

@implementation ShapeCell
@end

@interface GRefreshControl()
@property (strong, nonatomic) UIScrollView *superScrollView;
@property (strong, nonatomic) UIView *loadingView;
@property (nonatomic, strong) UIImageView *arrawImageView;
@property (strong, nonatomic) NSMutableArray *cellArray;

@property (strong, nonatomic) NSArray *originalColors;
@property (strong, nonatomic) NSArray *animationColors;

@property (assign, nonatomic) BOOL isLoading;
@property (assign, nonatomic) CGFloat superScroullViewInsetTop;

@end

@implementation GRefreshControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor grayColor];
        self.frame = CGRectMake(0, -kRefreshControlHeight, 320, kRefreshControlHeight);
        [self setupLoadingView];
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (self.superScrollView) {
        [self.superScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
    
    if ([newSuperview isKindOfClass:[UIScrollView class]]) {
        [newSuperview addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.superScroullViewInsetTop = self.superScrollView.contentInset.top;
}

- (void)setupLoadingView
{
    [self addSubview:self.loadingView];
    //cell offset
    NSArray *offsetYArr = @[@(-300),@(-220),@(-140),@(-100),@(0),@(-100),@(-140),@(-220),@(-300)];
    
    for (int i = 0; i< kCellNum; i++) {
        CAShapeLayer *shape = [CAShapeLayer layer];
        [self.loadingView.layer addSublayer:shape];
        
        ShapeCell *data = [[ShapeCell alloc]init];
        data.layer = shape;
        
        NSNumber *height = offsetYArr[i];
        data.frame = CGRectMake(kCellWidth*i,height.floatValue,
                                kCellWidth,
                                self.loadingView.frame.size.height);
        
        //填充色
        shape.fillColor = ((UIColor *)self.originalColors[i]).CGColor;
        //线头
        shape.lineCap = kCALineCapRound;
        shape.lineWidth = 0;
        shape.strokeColor = [UIColor grayColor].CGColor;
        shape.path = [UIBezierPath bezierPathWithRect:data.frame].CGPath;
        [self.cellArray addObject:data];
    }
    [self.loadingView.layer addAnimation:self.pullDown forKey:@"move"];
    self.loadingView.layer.speed = 0;
    [self addSubview:self.arrawImageView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:self.superScrollView];
    }
}

#pragma mark - 下拉监听

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.y + scrollView.contentInset.top;
    if (offset <= 0.0 && !self.isLoading) {
        //百分比进度
        CGFloat fractionDragged = -offset/kStartLoadingThreshold;
        self.loadingView.layer.timeOffset = MIN(1.0, fractionDragged);
        
        if (fractionDragged >= 1.0) {
            [UIView animateWithDuration:0.2 animations:^{
                self.arrawImageView.transform = CGAffineTransformMakeRotation(M_PI);
            }];
            
            if (!scrollView.dragging) {
                [self beginRefreshing];
            }
        } else {
            [UIView animateWithDuration:0.2 animations:^{
                self.arrawImageView.transform = CGAffineTransformMakeRotation(0);
            }];
        }
    }
}

#pragma mark - 开始加载数据

- (void)beginRefreshing
{
    if ([self.delegate respondsToSelector:@selector(refreshControlWillBeginRefreshing:)]) {
        [self.delegate refreshControlWillBeginRefreshing:self];
    }
    
    self.isLoading = YES;
    self.loadingView.layer.speed = 1.0f;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.superScrollView.contentInset = UIEdgeInsetsMake(self.superScroullViewInsetTop+kLodingHeight, 0, 0, 0);
    }];
    
    //给cell添加动画
    [self.cellArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ShapeCell *data = obj;
        [data.layer addAnimation:[self loadingWithIndex:idx] forKey:@"loading"];
    }];
    
    if ([self.delegate respondsToSelector:@selector(refreshControlDidBeginRefreshing:)]) {
        [self.delegate refreshControlDidBeginRefreshing:self];
    }
    
    //模拟结束
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self endRefreshing];
    });
}

#pragma mark - 结束加载数据
- (void)endRefreshing
{
    if ([self.delegate respondsToSelector:@selector(refreshControlWillEndRefreshing:)]) {
        [self.delegate refreshControlWillEndRefreshing:self];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        self.superScrollView.contentInset = UIEdgeInsetsMake(self.superScroullViewInsetTop, 0, 0, 0);
    }completion:^(BOOL finished) {
        [self.cellArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            ShapeCell *data = obj;
            
            [data.layer removeAllAnimations];
        }];
        
        [self.loadingView.layer removeAllAnimations];
        [self.loadingView.layer addAnimation:self.pullDown forKey:@"move"];
        self.loadingView.layer.speed = 0;
        self.loadingView.layer.timeOffset = 0;
        
        self.isLoading = NO;
    }];
    
    if ([self.delegate respondsToSelector:@selector(refreshControlDidEndRefreshing:)]) {
        [self.delegate refreshControlDidEndRefreshing:self];
    }
}

#pragma mark - view 初始化

- (UIImageView *)arrawImageView
{
    if (!_arrawImageView) {
        _arrawImageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:kRefreshArrawImageName]];
        _arrawImageView.frame = CGRectMake(0.5*(self.frame.size.width-_arrawImageView.frame.size.width), self.frame.size.height-17.0-_arrawImageView.frame.size.height, _arrawImageView.frame.size.width, _arrawImageView.frame.size.height);
    }
    return _arrawImageView;
}

- (UIView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[UIView alloc]initWithFrame:CGRectMake(0, -kRefreshControlHeight, self.frame.size.width, kRefreshControlHeight * 2)];
        _loadingView.backgroundColor = [UIColor clearColor];
    }
    return _loadingView;
}

- (UIScrollView *)superScrollView
{
    if (!_superScrollView) {
        if ([self.superview isKindOfClass:[UIScrollView class]]) {
            _superScrollView = (UIScrollView *)self.superview;
        }
    }
    return _superScrollView;
}

- (NSMutableArray *)cellArray
{
    if (!_cellArray) {
        _cellArray = [NSMutableArray array];
    }
    return _cellArray;
}

#pragma mark - 动画
- (CAAnimation *)pullDown
{
    CABasicAnimation * pullDown = [CABasicAnimation animationWithKeyPath:@"position.y"];
    pullDown.toValue = @(kRefreshControlHeight);
    pullDown.speed = 1;
    pullDown.duration = 1;
    
    return pullDown;
}

- (CAAnimationGroup *)loadingWithIndex:(NSUInteger)index
{
    CABasicAnimation * pullDown = [CABasicAnimation animationWithKeyPath:@"position.y"];
    pullDown.fromValue = @(kRefreshControlHeight);
    pullDown.toValue = @(kRefreshControlHeight);
    
    CAKeyframeAnimation *colorChange = [CAKeyframeAnimation animationWithKeyPath:@"fillColor"];
    colorChange.values = [self colorWithIndex:index];
    
    CAAnimationGroup *group = [[CAAnimationGroup alloc]init];
    group.duration = 1;
    group.speed = 1;
    group.repeatDuration = 1e100f;
    group.animations = @[pullDown,colorChange];
    
    return group;
}

- (NSArray *)colorWithIndex:(NSUInteger)index
{
    NSArray *colors = [self animationColors];
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:colors.count];
    
    for (int i = 0; i<colors.count; i++) {
        [array addObject:colors[(i+index)%colors.count]];
    }
    return array;
}

- (NSArray *)animationColors
{
    if (!_animationColors) {
        _animationColors = @[
                             (id)[UIColor colorWithHexString:@"#e8bf6c"].CGColor,
                             (id)[UIColor colorWithHexString:@"#e7e96c"].CGColor,
                             (id)[UIColor colorWithHexString:@"#a8e96c"].CGColor,
                             (id)[UIColor colorWithHexString:@"#88c16c"].CGColor,
                             (id)[UIColor colorWithHexString:@"#6b9fe9"].CGColor,
                             (id)[UIColor colorWithHexString:@"#946ce9"].CGColor,
                             (id)[UIColor colorWithHexString:@"#a96ce9"].CGColor,
                             (id)[UIColor colorWithHexString:@"#d46ce9"].CGColor,
                             (id)[UIColor colorWithHexString:@"#e86cd3"].CGColor];
    }
    return _animationColors;
}

- (NSArray *)originalColors
{
    if (!_originalColors) {
        _originalColors = @[[UIColor colorWithHexString:@"#e6aa33"],
                            [UIColor colorWithHexString:@"#e5e633"],
                            [UIColor colorWithHexString:@"#8ae633"],
                            [UIColor colorWithHexString:@"#5cad33"],
                            [UIColor colorWithHexString:@"#337ce6"],
                            [UIColor colorWithHexString:@"#6e33e6"],
                            [UIColor colorWithHexString:@"#8c33e6"],
                            [UIColor colorWithHexString:@"#c933e6"],
                            [UIColor colorWithHexString:@"#e633c7"]];
    }
    return _originalColors;
}

@end
