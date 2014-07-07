//
// Created by Manuel Maly on 07.07.14.
// Copyright (c) 2014 Creative Pragmatics GmbH. All rights reserved.
//

#import "MMGithubUserCell.h"
#import "MMGithubUser.h"

@interface MMGithubUserCell()

@property (strong, nonatomic) UILabel *userNameLabel;

@end

@implementation MMGithubUserCell

+ (instancetype)cellForTableView:(UITableView *)tableView style:(UITableViewCellStyle)style {
    NSString *cellID = [self cellIdentifier];
    MMGithubUserCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];

    if (!cell) {
        cell = [[[self class] alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.cellIdentifier];
    }

    return cell;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.userNameLabel = UILabel.new;

        [self addSubview:_userNameLabel];
    }

    return self;
}

+ (NSString *)cellIdentifier {
    return NSStringFromClass([self class]);
}

- (void)setUser:(MMGithubUser *)user {
    _user = user;

    self.userNameLabel.text = user.login;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.userNameLabel.frame = self.bounds;
}

@end