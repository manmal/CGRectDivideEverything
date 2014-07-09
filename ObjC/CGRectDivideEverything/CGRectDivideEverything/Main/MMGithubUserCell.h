//
// Created by Manuel Maly on 07.07.14.
// Copyright (c) 2014 Creative Pragmatics GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMGithubUser;
@class RACCommand;
@class MMLoadFullUserCommand;

@interface MMGithubUserCell : UITableViewCell

@property (strong, nonatomic) MMGithubUser *user;
@property (strong, nonatomic) MMLoadFullUserCommand *loadFullUserCommand;
@property (assign, nonatomic) BOOL expanded;

+ (instancetype)cellForTableView:(UITableView *)tableView style:(UITableViewCellStyle)style;

@end