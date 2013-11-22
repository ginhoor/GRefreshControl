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
#define kCellWidth 71/2.0f
#define kCellNum 9
#define kLodingHeight 5/2.0f

@interface ShapeCell : NSObject
@property (strong, nonatomic) CAShapeLayer *layer;
@property (assign, nonatomic) CGRect frame;
@end

@implementation ShapeCell
@end

@interface GRefreshControl()
@property (strong, nonatomic) UIScrollView *superScrollView;
@property (strong, nonatomic) UIView *loadingView;
@property (assign, nonatomic) BOOL isLoading;
@property (strong, nonatomic) NSMutableArray *cellArray;
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

        self.cellArray = [NSMutableArray array];
        
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
    self.loadingView = [[UIView alloc]init];
    [self addSubview:self.loadingView];
    
    self.loadingView.frame = CGRectMake(0, -kRefreshControlHeight, self.frame.size.width, kRefreshControlHeight * 2);
    self.loadingView.backgroundColor = [UIColor clearColor];
    
    
    NSArray *originalColors = @[[UIColor colorWithHexString:@"#e6aa33"],
                                [UIColor colorWithHexString:@"#e5e633"],
                                [UIColor colorWithHexString:@"#8ae633"],
                                [UIColor colorWithHexString:@"#5cad33"],
                                [UIColor colorWithHexString:@"#337ce6"],
                                [UIColor colorWithHexString:@"#6e33e6"],
                                [UIColor colorWithHexString:@"#8c33e6"],
                                [UIColor colorWithHexString:@"#c933e6"],
                                [UIColor colorWithHexString:@"#e633c7"]];
    
    
    //cell offset
    NSArray *offsetYArr = @[@(-300),@(-220),@(-140),@(-100),@(0),@(-100),@(-140),@(-220),@(-300)];
    
    for (int i = 0; i< kCellNum; i++) {
        
        CAShapeLayer *shape = [CAShapeLayer layer];
        [self.loadingView.layer addSublayer:shape];
        
        ShapeCell *data = [[ShapeCell alloc]init];

        NSNumber *height = offsetYArr[i];
        
        data.frame = CGRectMake(kCellWidth*i,height.floatValue, kCellWidth, self.loadingView.frame.size.height);
        
        data.layer = shape;
        //填充色
        shape.fillColor = ((UIColor *)originalColors[i]).CGColor;
        //线头
        shape.lineCap = kCALineCapRound;
        shape.lineWidth = 0;
        shape.strokeColor = [UIColor grayColor].CGColor;
        shape.path = [UIBezierPath bezierPathWithRect:data.frame].CGPath;
        [self.cellArray addObject:data];
    }
    
    [self.loadingView.layer addAnimation:self.pullDown forKey:@"move"];
    self.loadingView.layer.speed = 0;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:self.superScrollView];
    }
}

#pragma mark - pull down

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = scrollView.contentOffset.y + scrollView.contentInset.top;
    if (offset <= 0.0 && !self.isLoading) {
        //百分比进度
        CGFloat fractionDragged = -offset/kStartLoadingThreshold;
        self.loadingView.layer.timeOffset = MIN(1.0, fractionDragged);
        
        if (fractionDragged >= 1.0 && !scrollView.dragging) {
            [self beginRefreshing];
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
}


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


- (UIScrollView *)superScrollView
{
    if (!_superScrollView) {
        if ([self.superview isKindOfClass:[UIScrollView class]]) {
            _superScrollView = (UIScrollView *)self.superview;
        }
    }
    return _superScrollView;
}


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


- (CAAnimation *)finish
{
    return nil;
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
    return @[(id)[UIColor colorWithHexString:@"#e8bf6c"].CGColor,
             (id)[UIColor colorWithHexString:@"#e7e96c"].CGColor,
             (id)[UIColor colorWithHexString:@"#a8e96c"].CGColor,
             (id)[UIColor colorWithHexString:@"#88c16c"].CGColor,
             (id)[UIColor colorWithHexString:@"#6b9fe9"].CGColor,
             (id)[UIColor colorWithHexString:@"#946ce9"].CGColor,
             (id)[UIColor colorWithHexString:@"#a96ce9"].CGColor,
             (id)[UIColor colorWithHexString:@"#d46ce9"].CGColor,
             (id)[UIColor colorWithHexString:@"#e86cd3"].CGColor];
}


@end
