# Centralized Logging Pipeline
## Architecture
![output](/output.PNG)

## Environment configuration
### Localstack
```
cd {Project Path}
docker-compose up
```
### Terraform
```
terraform init
terraform workspace new dev
terraform workspace select dev
terraform apply
```
### 개념 검증
#### EC2(Nginx) - Kinesis
##### Localstack EC2
- Mac OS VirtualBox 만 지원하는 것을 확인
https://github.com/localstack/localstack-pro-samples/tree/master/ec2-custom-ami
##### Windows Ubuntu 사용
###### aws-kinesis-agent
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
###### aws kinesis put-record
```
aws kinesis put-record --stream-name stream --data '127.0.0.1 - - [10/Aug/2020:15:18:51 +0900] "GET / HTTP/1.1" 200 612 "-" "curl/7.58.0"' --endpoint http://localhost:4568 --partition-key "test"
```
#### Kinesis - Lambda
