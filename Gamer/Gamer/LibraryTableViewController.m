//
//  LibraryViewController.m
//  Gamer
//
//  Created by Caio Mello on 6/15/13.
//  Copyright (c) 2013 Caio Mello. All rights reserved.
//

#import "LibraryTableViewController.h"
#import "LibraryCell.h"
#import "Game.h"
#import "Platform.h"
#import "GameTableViewController.h"
#import "SearchTableViewController.h"

@interface LibraryTableViewController () <FetchedTableViewDelegate>

@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSPredicate *predicate;

@end

@implementation LibraryTableViewController

- (void)viewDidLoad{
    [super viewDidLoad];
	
	[self setEdgesForExtendedLayout:UIExtendedEdgeAll];
	
	[self.tableView setBackgroundColor:[UIColor colorWithRed:.098039216 green:.098039216 blue:.098039216 alpha:1]];
	[self.tableView.tableHeaderView setBackgroundColor:[UIColor clearColor]];
	[self.tableView setSeparatorColor:[UIColor darkGrayColor]];
	
	self.fetchedResultsController = [self fetchWithPredicate:_predicate];
}

- (void)viewWillAppear:(BOOL)animated{
	NSArray *favoritePlatforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"favorite = %@", @(YES)]];
	
	[_segmentedControl removeAllSegments];
	
	[_segmentedControl insertSegmentWithTitle:@"All" atIndex:0 animated:NO];
	for (Platform *platform in favoritePlatforms)
		[_segmentedControl insertSegmentWithTitle:platform.abbreviation atIndex:([favoritePlatforms indexOfObject:platform] + 1) animated:NO];
	
	[_segmentedControl setSelectedSegmentIndex:0];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.fetchedResultsController.sections[section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    LibraryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[cell setBackgroundColor:[UIColor colorWithRed:.125490196 green:.125490196 blue:.125490196 alpha:1]];
	[cell.titleLabel setTextColor:[UIColor lightGrayColor]];
	
	[self configureCell:cell atIndexPath:indexPath];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	[self performSegueWithIdentifier:@"GameSegue" sender:nil];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	//	[Game deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", game.identifier] inContext:context];
	[game setOwned:@(NO)];
	[context saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
		self.fetchedResultsController = [self fetchWithPredicate:_predicate];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
	}];
}

#pragma mark - FetchedTableView

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
	LibraryCell *customCell = (LibraryCell *)cell;
	
	Game *game = [self.fetchedResultsController objectAtIndexPath:indexPath];
	[customCell.titleLabel setText:game.title];
	[customCell.coverImageView setImage:[UIImage imageWithData:game.thumbnail]];
	[customCell.platformLabel setText:game.selectedPlatform.abbreviation];
	[customCell.platformLabel setBackgroundColor:game.selectedPlatform.color];
	[customCell.metascoreLabel setText:game.metascore];
}

#pragma mark - Fetch

- (NSFetchedResultsController *)fetchWithPredicate:(NSPredicate *)predicate{
	if (!self.fetchedResultsController)
		self.fetchedResultsController = [Game fetchAllGroupedBy:nil withPredicate:(predicate) ? predicate : [NSPredicate predicateWithFormat:@"owned = %@", @(YES)] sortedBy:@"title" ascending:YES delegate:self];
	return self.fetchedResultsController;
}

#pragma mark - Actions

- (IBAction)segmentedControlValueChanged:(UISegmentedControl *)sender{
	NSPredicate *predicate;
	
	if (sender.selectedSegmentIndex > 0){
		NSArray *platforms = [Platform findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"favorite = %@", @(YES)]];
		Platform *selectedPlatform = platforms[sender.selectedSegmentIndex - 1];
		predicate = [NSPredicate predicateWithFormat:@"owned = %@ AND selectedPlatform = %@", @(YES), selectedPlatform];
	}
	else
		predicate = nil;
	
	self.fetchedResultsController = [self fetchWithPredicate:predicate];
	[self.tableView reloadData];
}

- (IBAction)addBarButtonPressAction:(UIBarButtonItem *)sender{
	[self performSegueWithIdentifier:@"SearchSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
	if ([segue.identifier isEqualToString:@"GameSegue"]){
		GameTableViewController *destination = [segue destinationViewController];
		[destination setGame:[self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow]];
	}
//	if ([segue.identifier isEqualToString:@"SearchSegue"]){
//		SearchTableViewController *destination = [segue destinationViewController];
//		[destination setOrigin:2];
//	}
}

@end
