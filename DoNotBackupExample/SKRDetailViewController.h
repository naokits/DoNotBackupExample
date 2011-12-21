//
//  SKRDetailViewController.h
//  DoNotBackupExample
//
//  Created by Naoki TSUTSUI on 11/12/21.
//  Copyright (c) 2011年 Mercury Syscom, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SKRDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
