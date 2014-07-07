//
// Created by Manuel Maly on 07.07.14.
// Copyright (c) 2014 Creative Pragmatics GmbH. All rights reserved.
//

#import "MMMainViewModel.h"
#import "RACSignal.h"
#import <RACEXTScope.h>
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperationManager+RACSupport.h"
#import "MMGithubUser.h"

@interface MMMainViewModel()

@property (strong, nonatomic) AFHTTPRequestOperationManager *manager;

@end

@implementation MMMainViewModel

- (id)init {
    if (self = [super init]) {
        self.manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.github.com/"]];
        self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];

        RAC(self, users) = self.githubUsersSignal;
    }

    return self;
}

- (RACSignal *)githubUsersSignal {
    // Map each search term to a signal of its search result, and switch to the
    // latest search term value.
    @weakify(self)
    return [[RACObserve(self, searchTerm) map:^id(NSString *searchTerm) {
        if (searchTerm.length == 0) {
            return [RACSignal return:nil];
        }

        @strongify(self)
        return [[[self.manager rac_GET:@"search/users" parameters:@{@"q": searchTerm}] map:^id(NSDictionary *result) {
            return [[[result[@"items"] rac_sequence] map:^MMGithubUser *(NSDictionary *userDict) {
                return [MTLJSONAdapter modelOfClass:MMGithubUser.class fromJSONDictionary:userDict error:nil];
            }] array];
        }] replayLazily];
    }] switchToLatest];
}

@end