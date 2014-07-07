//
// Created by Manuel Maly on 07.07.14.
// Copyright (c) 2014 Creative Pragmatics GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMGithubUser;

@interface MMGithubUserCell : UITableViewCell

@property (strong, nonatomic) MMGithubUser *user;

+ (instancetype)cellForTableView:(UITableView *)tableView style:(UITableViewCellStyle)style;

@end