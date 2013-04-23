//
//  GameSearchViewController.h
//  Gamer
//
//  Created by Caio Mello on 4/22/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LibrarySearchTableViewController : UITableViewController <UISearchBarDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) NSMutableArray *results;

@property (nonatomic, strong) AFJSONRequestOperation *previousOperation;

@end
