//
// Created by Manuel Maly on 07.07.14.
// Copyright (c) 2014 Creative Pragmatics GmbH. All rights reserved.
//

#import "MMMainView.h"
#import "MMMainViewModel.h"
#import "MMGithubUserCell.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <RACEXTScope.h>

@interface MMMainView() <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UITextField *userNameField;
@property (strong, nonatomic) UIView *separatorView;
@property (strong, nonatomic) UITableView *tableView;

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
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        self.separatorView.backgroundColor = UIColor.blackColor;

        [self addSubview:_userNameField];
        [self addSubview:_separatorView];
        [self addSubview:_tableView];

        @weakify(self)
        [[RACObserve(self, viewModel.users) ignore:nil] subscribeNext:^(NSArray *users) {
            @strongify(self)
            [self.tableView reloadData];
        }];

        // Skip textfield's first value, and only return its latest content after a timeout.
        // If the user types within the timeout, the old value content is discared and the timout is restarted.
        RAC(self, viewModel.searchTerm) = [[[self.userNameField.rac_textSignal skip:1] map:^id(NSString *userName) {
            return [[RACSignal return:userName] delay:0.3f];
        }] switchToLatest];
    }

    return self;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect slice, remainder;

    // Cut status bar height
    CGRectDivide(self.bounds, &slice, &remainder, [UIApplication sharedApplication].statusBarFrame.size.height, CGRectMinYEdge);

    // Slice user name field and cut left and right margin
    CGRectDivide(remainder, &slice, &remainder, 50.f, CGRectMinYEdge);
    static const CGFloat userNameFieldHMargin = 16.f;
    self.userNameField.frame = CGRectInset(slice, userNameFieldHMargin, 0);

    // Slice separator and table view
    CGRectDivide(remainder, &slice, &remainder, 2.f, CGRectMinYEdge);
    self.separatorView.frame = slice;
    self.tableView.frame = remainder;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MMGithubUserCell *cell = [MMGithubUserCell cellForTableView:self.tableView style:UITableViewCellStyleDefault];
    cell.user = self.viewModel.users[indexPath.row];
    return cell;
}

@end