//
//  RefreshControl.h
//  demo4RefreshControl
//
//  Created by Ginhoor on 13-11-20.
//  Copyright (c) 2013年 Ginhoor. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GRefreshControl;

@protocol GRefreshControlDelegate <NSObject>

@optional
- (void)refreshControlWillBeginRefreshing:(GRefreshControl *)refreshControl;
- (void)refreshControlDidBeginRefreshing:(GRefreshControl *)refreshControl;
- (void)refreshControlWillEndRefreshing:(GRefreshControl *)refreshControl;
- (void)refreshControlDidEndRefreshing:(GRefreshControl *)refreshControl;

@end

@interface GRefreshControl : UIView
@property (nonatomic, weak) id<GRefreshControlDelegate> delegate;

- (void)beginRefreshing;
- (void)endRefreshing;

@end
