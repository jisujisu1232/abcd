import base64
import datetime
import gzip
import io
import json
import logging
import os
import urllib.parse
import uuid
import re

import boto3
import dateutil.parser
from aws_kinesis_agg.deaggregator import iter_deaggregate_records
from boto3.exceptions import S3UploadFailedError

# set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.info('Loading function')

# when debug logging is needed, uncomment following line:
# logger.setLevel(logging.DEBUG)



# configure with env vars
PATH_PREFIX = os.environ['LOG_S3_PREFIX']
BUCKET_NAME = os.environ['LOG_S3_BUCKET']
TEST_S3_ENDPOINT = os.environ['TEST_S3_ENDPOINT']


# global S3 client instance
s3_client_args = {}
s3_client_args['service_name'] = 's3'
if TEST_S3_ENDPOINT.strip():
    s3_client_args['endpoint_url'] = TEST_S3_ENDPOINT
    s3_client_args['use_ssl']       = False
    s3_client_args['verify']       = False

s3 = boto3.client(**s3_client_args)

# consts

parts = [
    r'(?P<host>\S+)',                   # $remote_addr
    r'\S+',                             # indent %l (unused)
    r'(?P<user>\S+)',                   # $remote_user
    r'\[(?P<time>.+)\]',                # [$time_local]
    r'"(?P<request>.*)"',               # "$request"
    r'(?P<status>[0-9]+)',              # $status
    r'(?P<size>\S+)',                   # $body_bytes_sent
    r'"(?P<referrer>.*)"',              # "$http_referer"
    r'"(?P<agent>.*)"',                 # "$http_user_agent"
	r'"(?P<client_ip>\S+)"',            # "$http_x_forwarded_for"
]

pattern = re.compile(r'\s+'.join(parts)+r'\s*\Z')

parts2 = [
    r'(?P<host>\S+)',                   # $remote_addr
    r'\S+',                             # indent %l (unused)
    r'(?P<user>\S+)',                   # $remote_user
    r'\[(?P<time>.+)\]',                # [$time_local]
    r'"(?P<request>.*)"',               # "$request"
    r'(?P<status>[0-9]+)',              # $status
    r'(?P<size>\S+)',                   # $body_bytes_sent
    r'"(?P<referrer>.*)"',              # "$http_referer"
    r'"(?P<agent>.*)"',                 # "$http_user_agent"
]

pattern2 = re.compile(r'\s+'.join(parts2)+r'\s*\Z')

log_timestamp = datetime.datetime.now()

def put_to_s3(key: str, bucket: str, data: str):
    # gzip and put data to s3 in-memory
    data_gz = gzip.compress(data.encode(), compresslevel=9)

    try:
        with io.BytesIO(data_gz) as data_gz_fileobj:
            s3_results = s3.upload_fileobj(data_gz_fileobj, bucket, key)

        logger.info(f"S3 upload errors: {s3_results}")

    except S3UploadFailedError as e:
        logger.error("Upload failed. Error:")
        logger.error(e)
        import traceback
        traceback.print_stack()
        raise

def normalize_kinesis_payload(p: str):
    # Normalize messages from CloudWatch (subscription filters) and pass through anything else
    # https://docs.aws.amazon.com/ja_jp/AmazonCloudWatch/latest/logs/SubscriptionFilters.html

    logger.debug(f"normalizer input: {p}")

    result = pattern.match(p)
    if result == None:
        result = pattern2.match(p)
    return result


def decode_validate(raw_records: list):

    log_list = []

    processed_records = 0

    for record in iter_deaggregate_records(raw_records):
        logger.debug(f"raw Kinesis record: {record}")
        # Kinesis data is base64 encoded
        decoded_data = base64.b64decode(record['kinesis']['data'])

        # check if base64 contents is gzip
        # gzip magic number 0x1f 0x8b
        if decoded_data[0] == 0x1f and decoded_data[1] == 0x8b:
            decoded_data = gzip.decompress(decoded_data)

        decoded_data = decoded_data.decode()
        normalized_payload = normalize_kinesis_payload(decoded_data)

        if normalized_payload == None:
            logger.error(f"{decoded_data}\nDecoded Data doesn't match the pattern.")
        else:
            normalized_payload = normalized_payload.groupdict()
            processed_records += 1

            log_list.append(json.dumps(normalized_payload))

    logger.info(f"Processed {processed_records} records from Kinesis")

    return log_list


def upload_by_type(log_list: list):
    if len(log_list) < 1:
        return

    # slashes in S3 object keys are like "directory" separators, like in ordinary filesystem paths
    key = PATH_PREFIX + '/'
    key += log_timestamp.strftime("%Y/%m/%d/%Y-%m-%d-%H:%M:%S-%f") + ".gz"

    logging.info(f"Starting upload to S3: s3://{BUCKET_NAME}/{key}")

    data = '\n'.join(log_list)
    put_to_s3(key, BUCKET_NAME, data)

    logger.info(f"Upload finished successfully")


def handler(event, context):
    raw_records = event['Records']

    log_list = decode_validate(raw_records)

    upload_by_type(log_list)
