//
//  ViewController.m
//  demo4RefreshControl
//
//  Created by Ginhoor on 13-11-19.
//  Copyright (c) 2013年 Ginhoor. All rights reserved.
//

#import "ViewController.h"

#import "GRefreshControl.h"


@interface ViewController () <UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (strong, nonatomic) NSMutableArray *cellDataArray;
@property (strong, nonatomic) NSMutableArray *cellArray;
@property (strong, nonatomic) UIView *mView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.table.delegate = self;
    self.table.dataSource = self;
//    self.automaticallyAdjustsScrollViewInsets = NO;
    self.edgesForExtendedLayout = UIRectEdgeBottom;
    [self.table addSubview:[[GRefreshControl alloc]init]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell * cell = [[UITableViewCell alloc]init];
    cell.textLabel.text = [NSString stringWithFormat:@"%d",indexPath.row];
    return cell;
}

@end
