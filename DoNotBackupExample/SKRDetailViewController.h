//
//  SKRDetailViewController.h
//  DoNotBackupExample
//
//  Created by Naoki TSUTSUI on 11/12/21.
//

#import <UIKit/UIKit.h>

@interface SKRDetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
