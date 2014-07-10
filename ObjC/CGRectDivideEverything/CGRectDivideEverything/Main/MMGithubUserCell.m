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
#import "MMRoundedButton.h"
#import "UIView+MMAdditions.h"
#import "UIImageView+AFNetworking.h"

static const CGFloat outerStrokeViewHInset = 10.f;
static const CGFloat outerStrokeViewBorderWidth = 2.f;
static const CGFloat innerStrokePadding = 10.f;

@interface MMGithubUserCell()

@property (assign, nonatomic) BOOL loading;

@property (strong, nonatomic) UIView *outerStrokeView;
@property (strong, nonatomic) UIImageView *avatarView;
@property (strong, nonatomic) UILabel *loginLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) MMRoundedButton *publicReposButton;
@property (strong, nonatomic) MMRoundedButton *publicGistsButton;
@property (strong, nonatomic) MMRoundedButton *followersLabel;
@property (strong, nonatomic) MMRoundedButton *followingLabel;
@property (strong, nonatomic) UILabel *companyDescLabel;
@property (strong, nonatomic) UILabel *companyLabel;
@property (strong, nonatomic) UILabel *hireableDescLabel;
@property (strong, nonatomic) UILabel *hireableLabel;
@property (strong, nonatomic) UILabel *profileURLDescLabel;
@property (strong, nonatomic) UILabel *profileURLLabel;
@property (strong, nonatomic) UILabel *blogDescLabel;
@property (strong, nonatomic) UILabel *blogLabel;

@end

@implementation MMGithubUserCell

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.outerStrokeView = [self.class makeStrokeView];
        self.avatarView = [self.class makeAvatarView];
        self.loginLabel = UILabel.new;
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];

        self.activityIndicator.hidesWhenStopped = YES;
        self.activityIndicator.color = UIColor.blackColor;

        [self addSubviews:@[_outerStrokeView, _avatarView, _loginLabel, _activityIndicator]];
    }

    return self;
}

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

+ (UIView *)makeStrokeView {
    UIView *strokeView = UIView.new;
    strokeView.layer.borderWidth = 2.f;
    strokeView.layer.borderColor = [UIColor colorWithRed:0.961 green:0.961 blue:0.961 alpha:1.0].CGColor;
    strokeView.layer.cornerRadius = 5.f;
    strokeView.layer.shouldRasterize = YES;
    strokeView.layer.rasterizationScale = UIScreen.mainScreen.scale;

    return strokeView;
}

+ (UIImageView *)makeAvatarView {
    UIImageView *avatarView = UIImageView.new;
    avatarView.clipsToBounds = YES;
    avatarView.layer.cornerRadius = 3.f;
    avatarView.layer.shouldRasterize = YES;
    avatarView.layer.rasterizationScale = UIScreen.mainScreen.scale;

    return avatarView;
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
    NSAssert(!(loadFullUserCommand && _loadFullUserCommand), @"loadFullUserCommand can only be set once after initial state or prepareForReuse.");
    _loadFullUserCommand = loadFullUserCommand;

    @weakify(self)
    // We don't do a RAC(self, user) assignment here because that would make it impossible
    // to make a binding from outside the cell (which might someday be necessary).
    [[[_loadFullUserCommand.executionSignals.flatten ignore:nil] takeUntil:self.rac_prepareForReuseSignal] subscribeNext:^(MMGithubUser *user) {
        @strongify(self)
        self.user = user;
    }];

    RAC(self, loading) = [loadFullUserCommand.executing takeUntil:self.rac_prepareForReuseSignal];
}

- (void)setUser:(MMGithubUser *)user {
    _user = user;

    self.loginLabel.text = user.name ?: user.login;
    [self.avatarView setImageWithURL:[NSURL URLWithString:user.avatarURL] placeholderImage:[UIImage imageNamed:@"octocat"]];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect nettoRect, slice, verticalRemainder, lineRemainder;

    // Outer stroke view has inset from bounds
    CGRect offsetBounds = CGRectOffset(self.bounds, 0, MMGithubUserCellOuterStrokeViewTopOffset);
    offsetBounds.size.height -= MMGithubUserCellOuterStrokeViewTopOffset * (self.isLastCell ? 2.f : 1.f);
    self.outerStrokeView.frame = CGRectInset(offsetBounds, outerStrokeViewHInset, 0);

    // Netto rect is where all the other elements align
    nettoRect = CGRectInset(self.outerStrokeView.frame, 10.f, 10.f);

    //////// Slice avatar, login label, and activity indicator ////////

    CGFloat avatarAndLoginHeight = MMGithubUserCellPartiallyLoadedHeight - MMGithubUserCellOuterStrokeViewTopOffset - 2 * innerStrokePadding;
    CGRectDivide(nettoRect, &slice, &lineRemainder, avatarAndLoginHeight, CGRectMinYEdge);

    // Slice avatar
    CGRectDivide(slice, &slice, &lineRemainder, avatarAndLoginHeight, CGRectMinXEdge);
    self.avatarView.frame = slice;

    // Slice activity indicator
    CGRectDivide(lineRemainder, &slice, &lineRemainder, 40.f, CGRectMaxXEdge);
    self.activityIndicator.frame = slice;

    // Cut padding avatar <> login label
    CGRectDivide(lineRemainder, &slice, &lineRemainder, 20.f, CGRectMinXEdge);

    // Cut padding activity indicator <> login label
    CGRectDivide(lineRemainder, &slice, &lineRemainder, 10.f, CGRectMaxXEdge);

    // Horizontal remainder is login label
    self.loginLabel.frame = lineRemainder;

}

#pragma mark - Teardown

- (void)prepareForReuse {
    self.loadFullUserCommand = nil;
}

@end