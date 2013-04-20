//
//  DTITCReportDownloadOperation.m
//  AutoIngest
//
//  Created by Oliver Drobnik on 4/20/13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "DTITCReportDownloadOperation.h"
#import "GenericAccount.h"

@implementation DTITCReportDownloadOperation
{
	ITCReportType _reportType;
	ITCReportSubType _reportSubType;
	ITCReportDateType _reportDateType;
	GenericAccount *_account;
	NSString *_vendorID;
	NSString *_reportFolder;
	
	NSError *_error;
}


- (id)initForReportsOfType:(ITCReportType)reportType subType:(ITCReportSubType)reportSubType dateType:(ITCReportDateType)reportDateType fromAccount:(GenericAccount *)account vendorID:(NSString *)vendorID intoFolder:(NSString *)folder;
{
	self = [super init];
	
	if (self)
	{
		_reportType = reportType;
		_reportSubType = reportSubType;
		_reportDateType = reportDateType;
		
		_account = account;
		_vendorID = [vendorID copy];
		
		_reportFolder = [folder copy];
	}
	
	return self;
}


- (void)main
{
	BOOL downloadAll = YES;
	
	// determine date to pass to download
	__block NSDate *reportDate;
	NSDate *today = [NSDate date];
	
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setDay:-1];
	
	reportDate = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:today options:0];
	
	// for weekly reports go back to previous Sunday
	if (_reportDateType == ITCReportDateTypeWeekly)
	{
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		
		NSDateComponents *comps = [gregorian components:NSWeekdayCalendarUnit fromDate:reportDate];
		
		if (comps.weekday!=1) // not a Sunday
		{
			comps.day = -(comps.weekday-1);
			comps.weekday = 0;
			
			reportDate = [gregorian dateByAddingComponents:comps toDate:reportDate options:0];
		}
	}
	
	// create a downloader
	DTITCReportDownloader *downloader = [[DTITCReportDownloader alloc] initWithUser:_account.account password:_account.password vendorIdentifier:_vendorID];
	
	__block NSUInteger downloadedFiles = 0;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	NSString *dateFormat = NSStringWithDateFormatForITCReportDateType(_reportDateType);
	
	[formatter setDateFormat:dateFormat];
	
	do
	{
		if ([self isCancelled])
		{
			break;
		}
		
		NSString *predictedName = [downloader predictedFileNameForDate:reportDate
																			 reportType:_reportType
																		reportDateType:_reportDateType
																		 reportSubType:_reportSubType
																			 compressed:YES];
		
		NSString *predictedOutputPath = [_reportFolder stringByAppendingPathComponent:predictedName];
		
		if ([fileManager fileExistsAtPath:predictedOutputPath])
		{
			NSLog(@"Skipped %@ because it already exists at %@", predictedName, _reportFolder);
			downloadedFiles++;
			
			if (!downloadAll)
			{
				break;
			}
		}
		else if ([downloader downloadReportWithDate:reportDate
													reportType:_reportType
											  reportDateType:_reportDateType
												reportSubType:_reportSubType
										  completionHandler:^(NSString *fileName, NSData *data) {
											  NSString *baseName = [fileName stringByReplacingOccurrencesOfString:@".txt.gz" withString:@""];
											  
											  // update actual report date
											  NSString *dateFormat = NSStringWithDateFormatForITCReportDateType(_reportDateType);
											  
											  NSString *dateStringInName = [baseName substringWithRange:NSMakeRange([baseName length]-[dateFormat length], [dateFormat length])];
											  formatter.dateFormat = dateFormat;
											  NSDate *parsedDate = [formatter dateFromString:dateStringInName];
											  
											  if ([parsedDate compare:reportDate] == NSOrderedDescending)
											  {
												  // cancel loop, this file does not fit with what we requested
												  reportDate = nil;
												  
												  return;
											  }
											  else
											  {
												  reportDate = parsedDate;
											  }
											  
											  // get current working directory
											  NSString *outputPath = [_reportFolder stringByAppendingPathComponent:fileName];
											  
											  // skip this file if output already exists
											  if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
											  {
												  NSLog(@"Skipped %@ because it already exists at %@", predictedName, _reportFolder);
												  downloadedFiles++;
												  
												  return;
											  }
											  
											  // write data to file
											  NSError *writeError = nil;
											  if ([data writeToFile:outputPath options:NSDataWritingAtomic error:&writeError])
											  {
												  NSLog(@"Downloaded Report %@", fileName);
												  downloadedFiles++;
											  }
											  else
											  {
												  NSLog(@"%@", [writeError localizedDescription]);
												  
											  }
										  }
					 
												 errorHandler:^(NSError *error) {
													 // if there is an URL connection error that is returned via this
													 NSError *networkError = [error userInfo][NSUnderlyingErrorKey];
													 
													 if (networkError)
													 {
														 _error = networkError; // network error, probably offline
													 }
													 else if ([[error localizedDescription] rangeOfString:@"Apple ID"].location != NSNotFound)
													 {
														 _error = error; // error message mentioning Apple ID probably means incorrect credentials
													 }
													 else if ([[error localizedDescription] rangeOfString:@"vendor number"].location != NSNotFound)
													 {
														 _error = error; // invalid vendor id
													 }
													 
													 if (_error && [_delegate respondsToSelector:@selector(operation:didFailWithError:)])
													 {
														 [_delegate operation:self didFailWithError:_error];
													 }
													 
													 NSLog(@"%@", [error localizedDescription]);
												 }])
		{
			// download succeeded for this date
			if (!downloadAll)
			{
				break;
			}
		}
		else
		{
			// download failed for this date
			if (!downloadAll)
			{
				// abort for single file
				break;
			}
			else
			{
				if (downloadedFiles>0)
				{
					// if we are downloading all the first failure means we end
					break;
				}
			}
		}
		
		if (downloadAll)
		{
			// move to one day/week/month/year earlier
			NSDateComponents *comps = [[NSDateComponents alloc] init];
			
			switch (_reportDateType)
			{
				case ITCReportDateTypeDaily:
				{
					[comps setDay:-1];
					break;
				}
					
				case ITCReportDateTypeWeekly:
				{
					[comps setDay:-7];
					break;
				}
					
				case ITCReportDateTypeMonthly:
				{
					[comps setMonth:-1];
					break;
				}
					
				case ITCReportDateTypeYearly:
				{
					[comps setYear:-1];
					break;
				}
					
				default:
				{
					break;
				}
			}
			
			if (!reportDate)
			{
				break;
			}
			
			reportDate = [[NSCalendar currentCalendar] dateByAddingComponents:comps toDate:reportDate options:0];
		}
		
	} while (!_error);
}

@end
