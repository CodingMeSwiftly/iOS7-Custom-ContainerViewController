//
//  INCCustomContainer.h
//  INCCustomContainer
//
//  Created by Maximilian Kraus on 04.03.14.
//
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Maximilian Kraus
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


#import "INCViewController.h"

#import "INCCustomContainer.h"

@interface INCViewController ()


@property (nonatomic) UILabel *label;

@property (nonatomic) UIButton *pushButton;

@end

@implementation INCViewController

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor colorWithRed:drand48() green:drand48() blue:drand48() alpha:1.0]];
    
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320.0, 128.0)];
    [self.label setTextAlignment:NSTextAlignmentCenter];
    [self.label setTextColor:[UIColor colorWithWhite:0.1 alpha:1.0]];
    [self.label setFont:[UIFont systemFontOfSize:40.0]];
    [self.view addSubview:self.label];
    
    [self.label setText:[NSString stringWithFormat:@"#%ld", self.customContainer.viewControllers.count]];
    
    self.pushButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.pushButton.titleLabel setFont:[UIFont systemFontOfSize:18.0]];
    [self.pushButton setTitle:@"Push ViewController" forState:UIControlStateNormal];
    [self.pushButton setFrame:CGRectMake(0, 0, 180.0, 24.0)];
    [self.pushButton setCenter:self.view.center];
    [self.pushButton addTarget:self action:@selector(pushButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.pushButton];
    
    
    [self setTitle:[NSString stringWithFormat:@"ViewController #%ld", self.customContainer.viewControllers.count]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"ViewWillAppear: %@", self.title);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSLog(@"ViewDidAppear: %@", self.title);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    NSLog(@"ViewWillDisappear: %@", self.title);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    NSLog(@"ViewDidDisappear: %@", self.title);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Button Handling

- (void)pushButtonTapped:(UIButton *)sender
{
    UIViewController *nextViewController = [[INCViewController alloc] init];
    
    [self.customContainer pushViewController:nextViewController animated:YES];
}

@end
