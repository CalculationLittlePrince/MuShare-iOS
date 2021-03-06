//
//  MyProfileTableViewController.m
//  MuShare-iOS
//
//  Created by 李大爷的电脑 on 7/14/16.
//  Copyright © 2016 limeng. All rights reserved.
//

#import "MyProfileTableViewController.h"
#import "DaoManager.h"
#import "DateTool.h"

@interface MyProfileTableViewController ()

@end

@implementation MyProfileTableViewController {
    DaoManager *dao;
    User *loginedUser;
}

- (void)viewDidLoad {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    dao = [[DaoManager alloc] init];
    loginedUser = [dao.userDao getLoginedUser];
    
    _nameLabel.text = loginedUser.name;
    _phoneLabel.text = loginedUser.phone;
    _genderLabel.text = loginedUser.gender == 0? @"Male": @"Female";
    _birthdayLabel.text = [DateTool formateDate:loginedUser.birth withFormat:DateFormatYearMonthDay];
}

#pragma mark - Table view data source
- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    //Clear header view color
    UIView *headerView = [[UIView alloc] init];
    [headerView setBackgroundColor:[UIColor clearColor]];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    return 0.1;
}

@end
