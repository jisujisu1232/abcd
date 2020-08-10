# Centralized Logging Pipeline
## 1.Architecture
![output](/output.PNG)

## 2. Environment configuration
### 2.1 Localstack
```
cd {Project Path}
docker-compose up
```
### 2.2 Terraform
```
terraform init
terraform workspace new dev
terraform workspace select dev
terraform apply
```
## 3. 개념 검증
### 3.1 EC2(Nginx) - Kinesis
#### 3.1.1 Localstack EC2
[Mac OS VirtualBox 만 지원하는 것을 확인](https://github.com/localstack/localstack-pro-samples/tree/master/ec2-custom-ami)

#### 3.1.2 Windows Ubuntu 사용
##### 3.1.2.1 aws-kinesis-agent
- /etc/aws-kinesis/agent.json
```
{
  "kinesis.endpoint": "http://localhost:4568",
  "cloudwatch.endpoint": "http://localhost:4582",
  "awsAccessKeyId": "temp",
  "awsSecretAccessKey": "temp",
  "flows": [
    {
      "filePattern": "/var/log/nginx/access.log",
      "kinesisStream": "stream",
      "maxBufferAgeMillis": 60000
    }
  ]
}
```
- localstack 에러 발생
```
localstack_demo | 2020-08-10T18:06:13:WARNING:localstack.utils.server.http2_server: Error in proxy handler for request POST http://localhost:4568/: 'utf-8' codec can't decode byte 0xbf in position 0: invalid start byte Traceback (most recent call last):
localstack_demo |   File "/opt/code/localstack/localstack/utils/server/http2_server.py", line 86, in index
localstack_demo |     result = await run_sync(handler, request, data)
localstack_demo |   File "/opt/code/localstack/localstack/utils/async_utils.py", line 50, in run_sync
localstack_demo |     return await loop.run_in_executor(THREAD_POOL, copy_context().run, func, *args)
localstack_demo |   File "/usr/lib/python3.8/concurrent/futures/thread.py", line 57, in run
localstack_demo |     result = self.fn(*self.args, **self.kwargs)
localstack_demo |   File "/opt/code/localstack/localstack/services/generic_proxy.py", line 555, in handler
localstack_demo |     response = modify_and_forward(method=method, path=path_with_params, data_bytes=data, headers=headers,
localstack_demo |   File "/opt/code/localstack/localstack/services/generic_proxy.py", line 332, in modify_and_forward
localstack_demo |     listener_result = listener.forward_request(method=method,
localstack_demo |   File "/opt/code/localstack/localstack/services/kinesis/kinesis_listener.py", line 27, in forward_request
localstack_demo |     data = json.loads(to_str(data or '{}'))
localstack_demo |   File "/opt/code/localstack/localstack/utils/common.py", line 766, in to_str
localstack_demo |     return obj.decode(encoding, errors) if isinstance(obj, six.binary_type) else obj
localstack_demo | UnicodeDecodeError: 'utf-8' codec can't decode byte 0xbf in position 0: invalid start byte
```
##### 3.1.2.2 aws kinesis put-record
```
aws kinesis put-record --stream-name stream --data '127.0.0.1 - - [10/Aug/2020:15:18:51 +0900] "GET / HTTP/1.1" 200 612 "-" "curl/7.58.0"' --endpoint http://localhost:4568 --partition-key "test"
{
    "ShardId": "shardId-000000000000",
    "SequenceNumber": "49609702820516273427131379532118303336149003465230647298"
}
```
Command 정상 완료 확인

### 3.2 Kinesis - Lambda
- localstack Log
Lambda 에서 구성된 Log 호출 확인
```
localstack_demo | 2020-08-10T19:38:09:INFO:root: Processed 1 records from Kinesis
localstack_demo | 2020-08-10T19:38:09:INFO:root: Starting upload to S3: s3://nginx-access-log-store-dev/nignx_access/2020/08/10/2020-08-10-17:14:56-.gz
localstack_demo | 2020-08-10T19:38:09:INFO:root: S3 upload errors: None
localstack_demo | 2020-08-10T19:38:09:INFO:root: Upload finished successfully
```
- CloudWatch Log
  - Log Group 확인
```
root@DESKTOP-4EUCKGD:/home/jisu# aws --endpoint-url=http://localhost:4586 logs describe-log-groups
{
    "logGroups": [
        {
            "logGroupName": "/aws/lambda/parsing_lambda",
            "creationTime": 1597047286060,
            "retentionInDays": 30,
            "metricFilterCount": 0,
            "arn": "arn:aws:logs:us-east-1:1:log-group:/aws/lambda/parsing_lambda",
            "storedBytes": 756
        }
    ]
}
```
  - Log Stream 확인
```
root@DESKTOP-4EUCKGD:/home/jisu# aws --endpoint-url=http://localhost:4586 logs describe-log-streams --log-group-name /aws/lambda/parsing_lambda
{
    "logStreams": [
        {
            "logStreamName": "2020/08/10/[LATEST]25e1e2b0",
            "creationTime": 1597047336413,
            "firstEventTimestamp": 1597047336374,
            "lastEventTimestamp": 1597047336374,
            "lastIngestionTime": 1597047336424,
            "uploadSequenceToken": "1",
            "arn": "arn:aws:logs:us-east-1:0:log-group:/aws/lambda/parsing_lambda:log-stream:2020/08/10/[LATEST]25e1e2b0",
            "storedBytes": 108
        },
        {
            "logStreamName": "2020/08/10/[LATEST]6392e23c",
            "creationTime": 1597055889481,
            "firstEventTimestamp": 1597055889451,
            "lastEventTimestamp": 1597055889451,
            "lastIngestionTime": 1597055889492,
            "uploadSequenceToken": "1",
            "arn": "arn:aws:logs:us-east-1:6:log-group:/aws/lambda/parsing_lambda:log-stream:2020/08/10/[LATEST]6392e23c",
            "storedBytes": 108
        }
    ]
}
```
  - Stream 확인
```
root@DESKTOP-4EUCKGD:/home/jisu# aws --endpoint-url=http://localhost:4586 logs get-log-events \
> --log-group-name /aws/lambda/parsing_lambda \
> --log-stream-name 2020/08/10/[LATEST]6392e23c
{
    "events": [
        {
            "timestamp": 1597055889451,
            "message": "START: Lambda arn:aws:lambda:us-east-1:000000000000:function:parsing_lambda started via \"local\" executor ...",
            "ingestionTime": 1597055889492
        }
    ],
    "nextForwardToken": "f/00000000000000000000000000000000000000000000000000000000",
    "nextBackwardToken": "b/00000000000000000000000000000000000000000000000000000000"
}
root@DESKTOP-4EUCKGD:/home/jisu# aws --endpoint-url=http://localhost:4586 logs get-log-events --log-group-name /aws/lambda/parsing_lambda --log-stream-name 2020/08/10/[LATEST]25e1e2b0
{
    "events": [
        {
            "timestamp": 1597047336374,
            "message": "START: Lambda arn:aws:lambda:us-east-1:000000000000:function:parsing_lambda started via \"local\" executor ...",
            "ingestionTime": 1597047336424
        }
    ],
    "nextForwardToken": "f/00000000000000000000000000000000000000000000000000000000",
    "nextBackwardToken": "b/00000000000000000000000000000000000000000000000000000000"
}
```

### 3.3 Lambda - S3
- Bucket 확인
```
root@DESKTOP-4EUCKGD:/home/jisu# aws s3 --endpoint-url http://localhost:4572 ls
2020-08-10 17:14:46 nginx-access-log-store-dev
```
- Object 확인
```
root@DESKTOP-4EUCKGD:/home/jisu# aws s3api get-object --endpoint-url http://localhost:4572 \
> --bucket nginx-access-log-store-dev \
> --key nignx_access/2020/08/10/2020-08-10-17:14:56-.gz \
> temp.gz
{
    "AcceptRanges": "bytes",
    "LastModified": "Mon, 10 Aug 2020 10:38:09 GMT",
    "ContentLength": 148,
    "ETag": "\"b61a13b65abaf8132402cefbe6e0ef0c\"",
    "CacheControl": "no-cache",
    "ContentEncoding": "identity",
    "ContentLanguage": "en-US",
    "ContentType": "binary/octet-stream",
    "Metadata": {}
}
root@DESKTOP-4EUCKGD:/home/jisu# gzip -d temp.gz
root@DESKTOP-4EUCKGD:/home/jisu# cat temp
{"host": "127.0.0.1", "user": "-", "time": "10/Aug/2020:15:18:51 +0900", "request": "GET / HTTP/1.1", "status": "200", "size": "612", "referrer": "-", "agent": "curl/7.58.0"}
```
