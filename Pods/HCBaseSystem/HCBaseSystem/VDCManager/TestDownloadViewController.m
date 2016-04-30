//
//  TestDownloadViewController.m
//  maiba
//
//  Created by HUANGXUTAO on 15/9/21.
//  Copyright © 2015年 seenvoice.com. All rights reserved.
//

#import "TestDownloadViewController.h"
#import "HttpVideoFileResponse.h"
#import "VDCTempFileInfo.h"
#import "VDCItem.h"

@interface TestDownloadViewController ()
{
    VDCItem * currentItem_;
    NSString * hostRoot_;
    NSArray * tempFileList_;
    HttpVideoFileResponse * response_;
    
}
@property (weak, nonatomic) IBOutlet UITextField *UrlField;
@property (weak, nonatomic) IBOutlet UITextField *pathField;
@property (weak, nonatomic) IBOutlet UITextField *localUrlField;
@property (weak, nonatomic) IBOutlet UITextField *fileSizeField;
@property (weak, nonatomic) IBOutlet UITextField *downloadedField;
@property (weak, nonatomic) IBOutlet UITableView *filesTableView;

@end

@implementation TestDownloadViewController

- (void)setHostRoot:(NSString *)hostRoot
{
    PP_RELEASE(hostRoot_);
    hostRoot_ = PP_RETAIN(hostRoot);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSString * url = @"http://7xjw4n.media2.z0.glb.qiniucdn.com/ot8sQzHIKvDgPG77L2aRtkA57o0=/lnCe0kowjDuF8obdqiAPWXmSKgzB";
    __block NSString * path = url;
    VDCManager * vdcManager = [VDCManager shareObject];
     [vdcManager addUrlCache:path title:@"未知" urlReady:^(VDCItem * vdcItem,NSURL * url)
                    {
                        currentItem_ = vdcItem;
                        NSLog(@"local url:%@",[url absoluteString]);
                        dispatch_async(dispatch_get_main_queue(), ^(void)
                                       {
                                           [self showInfo];
                                           
                                       });
                    } completed:nil];
    [self showInfo];
    
}
- (void)showInfo
{
    self.UrlField.text = currentItem_.remoteUrl;
    self.pathField.text = currentItem_.localFilePath;
    self.localUrlField.text = [currentItem_.localWebUrl stringByReplacingOccurrencesOfString:@"127.0.0.1" withString:hostRoot_];
    self.fileSizeField.text = [NSString stringWithFormat:@"%llu",currentItem_.contentLength];
    self.downloadedField.text = [NSString stringWithFormat:@"%llu",currentItem_.downloadBytes];
    NSLog(@"****----------------------------**");
    NSLog(@"tempfile:%@",currentItem_.tempFilePath);
    NSLog(@"localurl:%@",self.localUrlField.text);
    
    response_ = [[HttpVideoFileResponse alloc]initWithFilePath:currentItem_.tempFilePath forConnection:nil];
    
    [self.filesTableView reloadData];
}
- (IBAction)startClick:(id)sender {
    if(!currentItem_) return;
    NSError * error = nil;
    NSFileManager * fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:currentItem_.tempFilePath error:&error];
    if(error)
    {
        NSLog(@"error:%@",[error localizedDescription]);
    }
    [fm removeItemAtPath:currentItem_.localFilePath error:&error];
    if(error)
    {
        NSLog(@"error:%@",[error localizedDescription]);
    }
    VDCManager * vdcManager = [VDCManager shareObject];
    VDCTempFileInfo * nextFi = [vdcManager getNextTempSlideToDown:currentItem_ offset:0 minOffsetDownloading:nil];
    if(nextFi)
    {
        [vdcManager downloadNextSlide:currentItem_ offset:0 immediate:NO];
        [vdcManager downloadNextSlide:currentItem_ offset:0 immediate:NO];
//        [vdcManager downloadTempFile:nextFi
//                       urlReady:^(NSURL * url)
//         {
//             dispatch_async(dispatch_get_main_queue(), ^(void)
//                            {
//                                [self.filesTableView reloadData];
//                                
//                            });
//         }
//                       completed:^(VDCItem * item,BOOL completed,VDCTempFileInfo * tempFile)
//         {
//             if(completed)
//             {
//                 dispatch_async(dispatch_get_main_queue(), ^(void)
//                                {
//                                    [self.filesTableView reloadData];
//                                    
//                                });
//             }
//         }];
    }
}
- (IBAction)stopClick:(id)sender {
    //     VDCManager * vdcManager = [VDCManager shareObject];
    //    if(currentItem_ && currentItem_.operation)
    //    {
    //        [currentItem_.operation cancel];
    //    }
}
- (IBAction)queryFiles:(id)sender {
    response_ = [[HttpVideoFileResponse alloc]initWithFilePath:currentItem_.tempFilePath forConnection:nil];
    [self.filesTableView reloadData];
}
#pragma mark - tableview source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(currentItem_ && currentItem_.tempFileList)
        return currentItem_.tempFileList.count;
    else
        return 0;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cells"];
    if(!cell)
    {
        cell = [[UITableViewCell alloc]initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40)];
    }
    NSArray * tempList = currentItem_&& currentItem_.tempFileList?currentItem_.tempFileList:[NSArray new];
    
    VDCTempFileInfo * fi = [tempList objectAtIndex:tempList.count-1 - indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@: (%lld-%lld)",fi.fileName,fi.offset,fi.length];
    cell.textLabel.font = [UIFont systemFontOfSize:11.0f];
    return cell;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
