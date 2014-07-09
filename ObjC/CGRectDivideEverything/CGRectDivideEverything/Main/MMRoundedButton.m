//
// Created by Manuel Maly on 09.07.14.
// Copyright (c) 2014 Creative Pragmatics GmbH. All rights reserved.
//

#import "MMRoundedButton.h"


@implementation MMRoundedButton

- (id)init {
    if (self = [super init]) {
        self.layer.borderColor = [UIColor colorWithRed:0.859 green:0.859 blue:0.859 alpha:1.0].CGColor;
        self.layer.borderWidth = 2.f;
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = UIScreen.mainScreen.scale;
        self.titleLabel.font = [UIFont boldSystemFontOfSize:15.f];
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.adjustsImageWhenHighlighted = NO;
    }

    return self;
}

- (CGSize)intrinsicContentSize {
    CGSize titleLabelSize = self.titleLabel.intrinsicContentSize;
    return CGSizeMake(titleLabelSize.width + 20.f, titleLabelSize.height + 16.f);
}

@end