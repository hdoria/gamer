//
//  ImageCollectionCell.m
//  Gamer
//
//  Created by Caio Mello on 7/3/13.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "ImageCollectionCell.h"

@implementation ImageCollectionCell

- (void)setHighlighted:(BOOL)highlighted{
	[super setHighlighted:highlighted];
	
	if (highlighted){
		[self setAlpha:0.5];
	}
	else{
		[self setAlpha:1];
	}
}

@end
