//
//  ViewController.m
//  HYCListen
//
//  Created by eric on 2018/3/6.
//  Copyright © 2018年 eric. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+HYCListen.h"


@interface ViewController () <UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong)UITableView *tableView;

@property(nonatomic,strong)UIButton *clickBtn;


@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self addListen];
    
    [self initUI];
    
}

-(void)addListen{
    
    [self listen:@selector(tableView:didSelectRowAtIndexPath:) in:@protocol(UITableViewDelegate) withCallBack:^(NSArray *paramtersArray) {
        NSLog(@"%@",paramtersArray[0]);
    }];
    
    [self listen:@selector(clickUp:) withCallBack:^(NSArray *paramtersArray) {
        NSLog(@"%@",paramtersArray[0]);
    }];
    
}

-(void)initUI{
    
    self.clickBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
    [self.clickBtn addTarget:self action:@selector(clickUp:) forControlEvents:UIControlEventTouchUpInside];
    
    self.clickBtn.backgroundColor = [UIColor purpleColor];
    [self.view addSubview:self.clickBtn];
    
    self.tableView = [[UITableView alloc] init];
    [self.view addSubview:self.tableView];
    self.tableView.frame = CGRectMake(0,50,self.view.frame.size.width,self.view.frame.size.height);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
}

#pragma mark - UITableview Delegate

-(void)clickUp:(UIButton *)sender{
    NSLog(@"123");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [UITableViewCell new];
}

//-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    NSLog(@"click cell");
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
