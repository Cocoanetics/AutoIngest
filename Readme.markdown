AutoIngest for Mac
==================

Download your daily/weekly/monthly/yearly sales reports automatically to your harddisk.

This uses the [DTITCReportDownloader](https://github.com/Cocoanetics/DTITCReportDownloader) (aka "The Missing API") static library which is an [Open Source rewrite of Apple's AutoIngest.java](http://www.cocoanetics.com/2012/02/autoingest-java-in-objective-c/). 

If you see anything worth improving then just send a pull request! 

Follow [@cocoanetics](http://twitter.com/cocoanetics) on Twitter or subscribe to the [Cocoanetics Blog](http://www.cocoanetics.com) for news and updates.

To Do
=====

- replace the temporary status bar icon
- ~~animate this icon while downloading is occuring~~
- ~~change the "Sync Now" menu option to "Stop Sync" during download~~
- provide an app icon for the app
- ~~Add downloading on a timer~~
- Add counting of how many items where downloaded per type during a sync session
- report these via the didFinishNotification and output them in the user notification
- add UI to configure multiple accounts + Vendor IDs
- add support for Opt-In and Newsstand reports (I have no reports there so I cannot test them)
- add option to organize report folder: Vendor_ID/ReportType/ReportSubType/ReportDateType
- add Sparkle and automatic updating with Developer ID

If you have an idea that is not in this list, then please ask before getting to work on it.
