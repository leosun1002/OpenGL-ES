//
//  ViewController.m
//  GLSL_Test
//
//  Created by leosun on 2020/7/29.
//  Copyright © 2020 leosun. All rights reserved.
//

#import "ViewController.h"
#import "GLSLTestView.h"
@interface ViewController ()

@property(nonatomic,strong)GLSLTestView *myView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.myView = (GLSLTestView *)self.view;
    
    self.myView = (GLSLTestView *)self.view;
}


@end
