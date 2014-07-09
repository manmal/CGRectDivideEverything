//
// Created by Manuel Maly on 07.07.14.
// Copyright (c) 2014 Creative Pragmatics GmbH. All rights reserved.
//

#import "MMMainView.h"
#import "MMMainViewModel.h"
#import "MMGithubUserCell.h"
#import "MMGithubUser.h"
#import "MMLoadFullUserCommand.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <RACEXTScope.h>

@interface MMMainView() <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITextField *userNameField;
@property (strong, nonatomic) UIView *separatorView;
@property (strong, nonatomic) UITableView *tableView;
@property (assign, nonatomic) CGFloat shownKeyboardHeight;

@end

@implementation MMMainView

- (id)init {
    if (self = [super init]) {
        self.userNameField = UITextField.new;
        self.separatorView = UIView.new;
        self.tableView = UITableView.new;

        self.userNameField.placeholder = NSLocalizedString(@"Enter a Github user name...", nil);
        self.userNameField.font = [UIFont fontWithName:@"Futura-Medium" size:20.f];
        self.userNameField.autocorrectionType = UITextAutocorrectionTypeNo;
        self.userNameField.clearButtonMode = UITextFieldViewModeWhileEditing;
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.tableView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
        self.separatorView.backgroundColor = UIColor.blackColor;

        [self addSubview:_userNameField];
        [self addSubview:_separatorView];
        [self addSubview:_tableView];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setViewModel:(MMMainViewModel *)viewModel {
    NSAssert(_viewModel == nil, @"viewModel must not be set more than once.");
    _viewModel = viewModel;

    @weakify(self)
    [RACObserve(self.viewModel, partialUsers) subscribeNext:^(NSArray *users) {
        @strongify(self)
        [self.tableView reloadData];
    }];

    // Wait until a viewModel is set and then subscribe to its someUserFullyLoaded signal
    [self.viewModel.someUserFullyLoaded subscribeNext:^(MMGithubUser *user) {
        @strongify(self)
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }];

    // Skip textfield's first value, and only return its latest content after a timeout.
    // If the partialUser types within the timeout, the old value content is discared and the timout is restarted.
    RAC(self.viewModel, searchTerm) = [[[self.userNameField.rac_textSignal skip:1] map:^id(NSString *userName) {
        // Don't wait for an empty content.
        if (userName.length == 0) return [RACSignal return:nil];

        return [[RACSignal return:userName] delay:0.3f];
    }] switchToLatest];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect slice, remainder;

    // Cut status bar height
    CGRectDivide(self.bounds, &slice, &remainder, MIN([UIApplication sharedApplication].statusBarFrame.size.height, [UIApplication sharedApplication].statusBarFrame.size.width), CGRectMinYEdge);

    // Slice partialUser name field and cut left and right margin
    CGRectDivide(remainder, &slice, &remainder, 50.f, CGRectMinYEdge);
    static const CGFloat userNameFieldHMargin = 16.f;
    self.userNameField.frame = CGRectInset(slice, userNameFieldHMargin, 0);

    // Slice separator and table view
    CGRectDivide(remainder, &slice, &remainder, 2.f, CGRectMinYEdge);
    self.separatorView.frame = slice;
    self.tableView.frame = remainder;

    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.shownKeyboardHeight, 0);
    self.tableView.contentInset = self.tableView.scrollIndicatorInsets;
}

#pragma mark - Keyboard Handling

- (void)keyboardWillHide:(NSNotification *)notification {
    self.shownKeyboardHeight = 0.f;
    [self layoutSubviews];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.shownKeyboardHeight = MIN(keyboardSize.height, keyboardSize.width);
    [self layoutSubviews];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.partialUsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MMGithubUserCell *cell = [MMGithubUserCell cellForTableView:self.tableView style:UITableViewCellStyleDefault];
    MMGithubUser *partialUser = self.viewModel.partialUsers[indexPath.row];
    cell.user = self.viewModel.fullyLoadedUsers[partialUser.login] ?: partialUser;
    cell.loadFullUserCommand = [self.viewModel loadFullUserCommand:cell.user createIfNotExists:NO];
    cell.isLastCell = indexPath.row == self.viewModel.partialUsers.count - 1;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self endEditing:YES];

    MMGithubUserCell *cell = (MMGithubUserCell *)[self.tableView cellForRowAtIndexPath:indexPath];

    // Lazily set command now because setting it in tableView:cellForRowAtIndexPath: could cause jerky scrolling
    if (!cell.loadFullUserCommand) {
        cell.loadFullUserCommand = [self.viewModel loadFullUserCommand:self.viewModel.partialUsers[indexPath.row] createIfNotExists:YES];
    }

    [cell.loadFullUserCommand execute:nil];

    cell.expanded = !cell.expanded;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    MMGithubUser *partialUser = self.viewModel.partialUsers[indexPath.row];

    CGFloat contentHeight;

    if (self.viewModel.fullyLoadedUsers[partialUser.login]) {
        contentHeight = MMGithubUserCellFullyLoadedHeight;
    } else {
        contentHeight = MMGithubUserCellPartiallyLoadedHeight;
    }

    if (indexPath.row == self.viewModel.partialUsers.count - 1) {
        contentHeight += MMGithubUserCellOuterStrokeViewTopOffset;
    }

    return contentHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.1f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return UIView.new;
}

@end