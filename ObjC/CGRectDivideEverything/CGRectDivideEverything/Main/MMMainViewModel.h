//
// Created by Manuel Maly on 07.07.14.
// Copyright (c) 2014 Creative Pragmatics GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RACCommand;
@class MMGithubUser;
@class MMLoadFullUserCommand;


@interface MMMainViewModel : NSObject

@property (copy, nonatomic) NSString *searchTerm;
@property (copy, nonatomic) NSArray *users;

- (MMLoadFullUserCommand *)loadFullUserCommand:(MMGithubUser *)user createIfNotExists:(BOOL)createIfNotExists;

@end