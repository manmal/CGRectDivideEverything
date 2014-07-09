//
// Created by Manuel Maly on 07.07.14.
// Copyright (c) 2014 Creative Pragmatics GmbH. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa/RACCommand.h>
#import <ReactiveCocoa/ReactiveCocoa/RACSignal+Operations.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import <ReactiveCocoa/ReactiveCocoa/RACSubscriptingAssignmentTrampoline.h>
#import "MMLoadFullUserCommand.h"
#import <ReactiveCocoa/ReactiveCocoa/NSObject+RACPropertySubscribing.h>
#import <ReactiveCocoa/ReactiveCocoa/UITableViewCell+RACSignalSupport.h>
#import "MMGithubUserCell.h"
#import "MMGithubUser.h"

@interface MMGithubUserCell()

@property (strong, nonatomic) UILabel *userNameLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (assign, nonatomic) BOOL loading;

@end

@implementation MMGithubUserCell

#pragma mark - Initialization

+ (instancetype)cellForTableView:(UITableView *)tableView style:(UITableViewCellStyle)style {
    NSString *cellID = [self cellIdentifier];
    MMGithubUserCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];

    if (!cell) {
        cell = [[[self class] alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.cellIdentifier];
    }

    return cell;
}

+ (NSString *)cellIdentifier {
    return NSStringFromClass([self class]);
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.userNameLabel = UILabel.new;
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

        self.activityIndicator.hidesWhenStopped = YES;
        self.activityIndicator.color = UIColor.blackColor;

        [self addSubview:_userNameLabel];
        [self addSubview:_activityIndicator];

        RAC(self, loading) = [[RACObserve(self, loadFullUserCommand) map:^id(MMLoadFullUserCommand *loadFullUserCommand) {
            return loadFullUserCommand.executing;
        }] switchToLatest];
    }

    return self;
}

#pragma mark - Attribute Accessors

- (void)setLoading:(BOOL)loading {
    if (_loading == loading) return;

    _loading = loading;
    if (loading) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
}

- (void)setLoadFullUserCommand:(MMLoadFullUserCommand *)loadFullUserCommand {
    // Command can only be set once after initial state or prepareForReuse.
    if (_loadFullUserCommand) return;
    _loadFullUserCommand = loadFullUserCommand;

    @weakify(self)
    // We don't do a RAC(self, user) assignment here because that would make it impossible
    // to make a binding from outside the cell (which might someday be necessary).
    [[[_loadFullUserCommand.executionSignals.flatten ignore:nil] takeUntil:self.rac_prepareForReuseSignal] subscribeNext:^(MMGithubUser *user) {
        @strongify(self)
        self.user = user;
    }];
}

- (void)setUser:(MMGithubUser *)user {
    _user = user;

    self.userNameLabel.text = user.name ?: user.login;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    self.userNameLabel.frame = self.bounds;
    self.activityIndicator.frame = CGRectMake(100, 0, 40, 40);
}

#pragma mark - Teardown

- (void)prepareForReuse {
    self.loadFullUserCommand = nil;
}

@end