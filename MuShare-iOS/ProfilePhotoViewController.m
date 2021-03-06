//
//  ProfilePhotoViewController.m
//  MuShare-iOS
//
//  Created by 李大爷的电脑 on 7/16/16.
//  Copyright © 2016 limeng. All rights reserved.
//

#import "ProfilePhotoViewController.h"
#import <AliyunOSSiOS/OSSService.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AlertTool.h"
#import "InternetHelper.h"
#import "DaoManager.h"

@interface ProfilePhotoViewController ()

@end

@implementation ProfilePhotoViewController {
    UIImagePickerController *imagePickerController;
    AFHTTPSessionManager *manager;
    DaoManager *dao;
    User *loginedUser;
    id<OSSCredentialProvider> credential;
    OSSClient *client;
}

- (void)viewDidLoad {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    [super viewDidLoad];
    dao = [[DaoManager alloc] init];
    loginedUser=[dao.userDao getLoginedUser];
    manager=[InternetHelper getSessionManager: loginedUser.token];
    
    //Init ImagePickerController
    imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.delegate = self;
    
    //Init Aliyun OSS
    [self initAliyunOSS];
}

#pragma mark - UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class,NSStringFromSelector(_cmd));
        NSLog(@"MediaInfo: %@", info);
    }
    // 获取用户拍摄的是照片还是视频
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    // 判断获取类型：图片
    if([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        _profilePhotoImageView.image = [info objectForKey:UIImagePickerControllerEditedImage];
    }
    //Hide UIImagePickerController
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    
    //Upload image to aliyun OSS
    if(_profilePhotoImageView.image != nil) {
        [self uploadAvatar];
    }
}

#pragma mark - Action
- (IBAction)editProfilePhoto:(id)sender {
    if(DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Edit Profile Photo"
                                                                             message:@"Choose a photo from library or take a photo."
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:@"Take Photo"
                                                       style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            // 将sourceType设为UIImagePickerControllerSourceTypeCamera代表拍照或拍视频
            imagePickerController.sourceType=UIImagePickerControllerSourceTypeCamera;
            // 设置模式为拍摄照片
            imagePickerController.cameraCaptureMode=UIImagePickerControllerCameraCaptureModePhoto;
            // 设置使用手机的后置摄像头（默认使用后置摄像头）
            imagePickerController.cameraDevice=UIImagePickerControllerCameraDeviceRear;
            // 设置拍摄的照片允许编辑
            imagePickerController.allowsEditing=YES;
        }else{
            if(DEBUG) {
                NSLog(@"iOS Simulator cannot open camera.");
            }
            [AlertTool showAlertWithTitle:@"Warning"
                               andContent:@"iOS Simulator cannot open camera."
                         inViewController:self];
        }
        // 显示picker视图控制器
        [self presentViewController:imagePickerController animated: YES completion:nil];
    }];
    
    UIAlertAction *choose = [UIAlertAction actionWithTitle:@"Choose from Photos"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * _Nonnull action) {
        // 设置选择载相册的图片
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.allowsEditing = YES;
        // 显示picker视图控制器
        [self presentViewController:imagePickerController animated: YES completion:nil];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
    [alertController addAction:takePhoto];
    [alertController addAction:choose];
    [alertController addAction:cancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Service 
- (void)initAliyunOSS {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    NSString *endpoint = @"http://oss-cn-qingdao.aliyuncs.com";
    credential =  [[OSSFederationCredentialProvider alloc] initWithFederationTokenGetter:^OSSFederationToken *{
        NSURL * url = [NSURL URLWithString:[InternetHelper createUrl:@"api/oss/sts/get"]];
        
        //1.创建request
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        //2.创建一个 NSMutableURLRequest 添加 header
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        [mutableRequest addValue:loginedUser.token forHTTPHeaderField:@"Authorization"];
        
        //3.把值覆给request
        request = [mutableRequest copy];
        
        OSSTaskCompletionSource * tcs = [OSSTaskCompletionSource taskCompletionSource];
        NSURLSession * session = [NSURLSession sharedSession];
        
        // 发送请求
        NSURLSessionTask * sessionTask = [session dataTaskWithRequest:request
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                        if (error) {
                                                            [tcs setError:error];
                                                            return;
                                                        }
                                                        [tcs setResult:data];
                                                    }];
        [sessionTask resume];
        
        // 需要阻塞等待请求返回
        [tcs.task waitUntilFinished];
        
        // 解析结果
        if (tcs.task.error) {
            NSLog(@"get token error: %@", tcs.task.error);
            return nil;
        } else {
            // 返回数据是json格式，需要解析得到token的各个字段
            NSDictionary * object = [NSJSONSerialization JSONObjectWithData:tcs.task.result
                                                                    options:kNilOptions
                                                                      error:nil];
            object = [object valueForKey:@"body"];
            NSLog(@"get token: %@", object);
            OSSFederationToken * token = [OSSFederationToken new];
            token.tAccessKey = [object objectForKey:@"accessKeyId"];
            token.tSecretKey = [object objectForKey:@"accessKeySecret"];
            token.tToken = [object objectForKey:@"securityToken"];
            token.expirationTimeInGMTFormat = [object objectForKey:@"expiration"];
            NSLog(@"get token: %@ %@ %@", token.tAccessKey, token.tSecretKey, token.tToken);
            return token;
        }
    }];
    
    client = [[OSSClient alloc] initWithEndpoint:endpoint credentialProvider:credential];
}

- (void)uploadAvatar {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    OSSPutObjectRequest * put = [OSSPutObjectRequest new];
    
    put.bucketName = @"mushare";
    put.objectKey = [NSString stringWithFormat:@"avatar-%@.jpg", loginedUser.sid];
    put.callbackParam = @{
                          @"callbackUrl": [InternetHelper createUrl:@"api/oss/operation/upload"],
                          @"callbackBody": @"{'bucket': ${bucket}, 'object': ${object}, 'uid'=${x:uid}}",
                          @"callbackBodyType": @"application/json"
                          };
    put.callbackVar = @{
                        @"x:uid": [NSString stringWithFormat:@"%@", loginedUser.sid]
                        };
    put.objectMeta = @{
                       @"x-oss-meta-token": loginedUser.token
                       };
    
    put.uploadingData = UIImageJPEGRepresentation(_profilePhotoImageView.image, 1.0); // 直接上传NSData
    
    put.uploadProgress = ^(int64_t bytesSent, int64_t totalByteSent, int64_t totalBytesExpectedToSend) {
        NSLog(@"%lld, %lld, %lld", bytesSent, totalByteSent, totalBytesExpectedToSend);
    };
    
    OSSTask * putTask = [client putObject:put];
    
    [putTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSLog(@"upload object success!");
            OSSPutObjectResult * result = task.result;
            NSLog(@"Result - requestId: %@, headerFields: %@, servercallback: %@",
                  result.requestId,
                  result.httpResponseHeaderFields,
                  result.serverReturnJsonString);
        } else {
            NSLog(@"upload object failed, error: %@" , task.error);
        }
        return nil;
    }];
    
}

- (void)downloadAvatar {
    if (DEBUG) {
        NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
    }
    OSSGetObjectRequest * request = [OSSGetObjectRequest new];
    
    // 必填字段
    request.bucketName = @"mushare";
    request.objectKey = @"avatar.jpg";
    
    // 可选字段
    request.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        // 当前下载段长度、当前已经下载总长度、一共需要下载的总长度
        NSLog(@"%lld, %lld, %lld", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    };
    // request.range = [[OSSRange alloc] initWithStart:0 withEnd:99]; // bytes=0-99，指定范围下载
    // request.downloadToFileURL = [NSURL fileURLWithPath:@"<filepath>"]; // 如果需要直接下载到文件，需要指明目标文件地址
    
    OSSTask * getTask = [client getObject:request];
    
    [getTask continueWithBlock:^id(OSSTask *task) {
        if (!task.error) {
            NSLog(@"download object success!");
            OSSGetObjectResult * getResult = task.result;
            NSLog(@"download result: %@", getResult.downloadedData);
        } else {
            NSLog(@"download object failed, error: %@" ,task.error);
        }
        return nil;
    }];
}

@end
