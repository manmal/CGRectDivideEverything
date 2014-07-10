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

static const CGFloat outerStrokeViewBorderWidth = 2.f;

@interface MMGithubUserCell()

@property (assign, nonatomic) BOOL loading;

@property (strong, nonatomic) UIView *outerStrokeView;
@property (strong, nonatomic) UIImageView *avatarView;
@property (strong, nonatomic) UILabel *loginLabel;
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) MMRoundedButton *reposButton;
@property (strong, nonatomic) MMRoundedButton *gistsButton;
@property (strong, nonatomic) MMRoundedButton *followersButton;
@property (strong, nonatomic) MMRoundedButton *followingButton;
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
        self.loginLabel = [self.class makeLabelWithFontSize:20.f];
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.reposButton = MMRoundedButton.new;
        self.gistsButton = MMRoundedButton.new;
        self.followersButton = MMRoundedButton.new;
        self.followingButton = MMRoundedButton.new;

        self.activityIndicator.hidesWhenStopped = YES;
        self.activityIndicator.color = UIColor.blackColor;

        [self addSubviews:@[_outerStrokeView, _avatarView, _loginLabel, _activityIndicator, _reposButton, _gistsButton, _followersButton, _followingButton]];
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
    strokeView.layer.borderWidth = outerStrokeViewBorderWidth;
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

+ (UILabel *)makeLabelWithFontSize:(CGFloat)fontSize {
    UILabel *label = UILabel.new;
    label.font = [UIFont fontWithName:@"Futura-Medium" size:fontSize];
    label.backgroundColor = UIColor.clearColor;
    return label;
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

    [[[[RACSignal combineLatest:@[[RACObserve(self, user.fullyLoaded) distinctUntilChanged], [RACObserve(self, expanded) distinctUntilChanged]] reduce:^id(NSNumber *fullyLoaded, NSNumber *expanded) {
        return @(fullyLoaded.boolValue && expanded.boolValue);
    }] distinctUntilChanged] takeUntil:self.rac_prepareForReuseSignal] subscribeNext:^(NSNumber *animateToFullState) {
        CGFloat alpha = animateToFullState.boolValue ? 1.f : 0.f;
        NSTimeInterval duration = animateToFullState.boolValue ? 0.5f : 0.3f;
        NSTimeInterval delay = animateToFullState.boolValue ? 0.3f : 0.f;
        [UIView animateWithDuration:duration delay:delay options:0 animations:^{
            self.reposButton.alpha = alpha;
            self.gistsButton.alpha = alpha;
            self.followersButton.alpha = alpha;
            self.followingButton.alpha = alpha;
        } completion:nil];
    }];

    RAC(self, loading) = [loadFullUserCommand.executing takeUntil:self.rac_prepareForReuseSignal];
}

- (void)setUser:(MMGithubUser *)user {
    _user = user;

    self.loginLabel.text = user.name ?: user.login;
    [self.avatarView setImageWithURL:[NSURL URLWithString:user.avatarURL] placeholderImage:[UIImage imageNamed:@"octocat"]];
    [self.reposButton setTitle:(user.fullyLoaded ? [NSString stringWithFormat:@"%d Repos", user.publicRepos] : nil) forState:UIControlStateNormal];
    [self.gistsButton setTitle:(user.fullyLoaded ? [NSString stringWithFormat:@"%d Gists", user.publicGists] : nil) forState:UIControlStateNormal];
    [self.followersButton setTitle:(user.fullyLoaded ? [NSString stringWithFormat:@"%d Followers", user.followers] : nil) forState:UIControlStateNormal];
    [self.followingButton setTitle:(user.fullyLoaded ? [NSString stringWithFormat:@"Following %d", user.following] : nil) forState:UIControlStateNormal];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    static const CGFloat outerStrokeViewHInset = 10.f;
    static const CGFloat innerStrokePadding = 10.f;
    static const CGFloat activityIndicatorWidth = 40.f;
    static const CGFloat avatarToLoginLabelMargin = 20.f;
    static const CGFloat activityIndicatorToLoginLabelMargin = 10.f;
    static const CGFloat firstToSecondLineMargin = 15.f;
    static const CGFloat secondToThirdLineMargin = 8.f;

    CGRect nettoRect, slice, verticalRemainder, lineRemainder;

    // Outer stroke view has inset from bounds
    CGRect offsetBounds = CGRectOffset(self.bounds, 0, MMGithubUserCellOuterStrokeViewTopOffset);
    offsetBounds.size.height -= MMGithubUserCellOuterStrokeViewTopOffset * (self.isLastCell ? 2.f : 1.f);
    self.outerStrokeView.frame = CGRectInset(offsetBounds, outerStrokeViewHInset, 0);

    // Netto rect is where all the other elements align
    nettoRect = CGRectInset(self.outerStrokeView.frame, innerStrokePadding, innerStrokePadding);


    //////// 1. line (avatar, login label, and activity indicator) ////////

    CGFloat firstLineHeight = MMGithubUserCellPartiallyLoadedHeight - MMGithubUserCellOuterStrokeViewTopOffset - 2 * innerStrokePadding;
    CGRectDivide(nettoRect, &slice, &verticalRemainder, firstLineHeight, CGRectMinYEdge);

    // Slice avatar
    CGRectDivide(slice, &slice, &lineRemainder, firstLineHeight, CGRectMinXEdge);
    self.avatarView.frame = slice;

    // Slice activity indicator
    CGRectDivide(lineRemainder, &slice, &lineRemainder, activityIndicatorWidth, CGRectMaxXEdge);
    self.activityIndicator.frame = slice;

    // Cut padding avatar <> login label
    CGRectDivide(lineRemainder, &slice, &lineRemainder, avatarToLoginLabelMargin, CGRectMinXEdge);

    // Cut padding activity indicator <> login label
    CGRectDivide(lineRemainder, &slice, &lineRemainder, activityIndicatorToLoginLabelMargin, CGRectMaxXEdge);

    // Horizontal remainder is login label
    self.loginLabel.frame = lineRemainder;


    //////// 2. line (repos and gists button) ////////

    // Cut horizontal padding between 1. and 2. line
    CGRectDivide(verticalRemainder, &slice, &verticalRemainder, firstToSecondLineMargin, CGRectMinYEdge);

    // Slice 2. line
    CGFloat secondLineHeight = self.reposButton.intrinsicContentSize.height;
    CGRectDivide(verticalRemainder, &slice, &verticalRemainder, secondLineHeight, CGRectMinYEdge);
    [self layoutEvenlyDistributedButtonsInRect:slice leftButton:self.reposButton rightButton:self.gistsButton];


    //////// 3. line (followers and following button) ////////

    // Cut horizontal padding between 2. and 3. line
    CGRectDivide(verticalRemainder, &slice, &verticalRemainder, secondToThirdLineMargin, CGRectMinYEdge);

    // Slice 2. line
    CGFloat thirdLineHeight = self.followingButton.intrinsicContentSize.height;
    CGRectDivide(verticalRemainder, &slice, &verticalRemainder, thirdLineHeight, CGRectMinYEdge);
    [self layoutEvenlyDistributedButtonsInRect:slice leftButton:self.followersButton rightButton:self.followingButton];

}

- (void)layoutEvenlyDistributedButtonsInRect:(CGRect)rect leftButton:(UIButton *)leftButton rightButton:(UIButton *)rightButton {
    static const CGFloat twoEvenlyDistributedButtonsMargin = 5.f;
    CGFloat twoEvenlyDistributedButtonsButtonWidth = (CGRectGetWidth(rect) - twoEvenlyDistributedButtonsMargin) / 2.f;
    CGRect slice, remainder;

    // Slice repos button
    CGRectDivide(rect, &slice, &remainder, twoEvenlyDistributedButtonsButtonWidth, CGRectMinXEdge);
    leftButton.frame = slice;

    // Cut buttons margin
    CGRectDivide(remainder, &slice, &remainder, twoEvenlyDistributedButtonsMargin, CGRectMinXEdge);

    // Right button is remainder
    rightButton.frame = remainder;
}

#pragma mark - Teardown

- (void)prepareForReuse {
    self.reposButton.alpha = self.gistsButton.alpha = self.followersButton.alpha = self.followingButton.alpha = 0.f;
    self.expanded = NO;
    self.loadFullUserCommand = nil;
}

@end