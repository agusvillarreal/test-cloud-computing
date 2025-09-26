#!/usr/bin/env python3
"""
Simple AWS S3 connection script
"""

import os
import boto3
from dotenv import load_dotenv

def connect_to_s3():
    """Connect to AWS S3 using credentials from .env file"""
    # Load environment variables from .env file
    load_dotenv()
    
    # Get AWS credentials from environment variables
    access_key = os.getenv('AWS_ACCESS_KEY_ID')
    secret_key = os.getenv('AWS_SECRET_ACCESS_KEY')
    region = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
    
    if not access_key or not secret_key:
        print("Error: AWS credentials not found in .env file")
        print("Please update .env file with your AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY")
        return None
    
    try:
        # Create S3 client
        s3_client = boto3.client(
            's3',
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
            region_name=region
        )
        
        print(f"Successfully connected to S3 in region: {region}")
        
        # List all S3 buckets to verify connection
        response = s3_client.list_buckets()
        buckets = response['Buckets']
        
        print(f"Found {len(buckets)} bucket(s):")
        for bucket in buckets:
            print(f"  - {bucket['Name']} (created: {bucket['CreationDate']})")
        
        return s3_client
        
    except Exception as e:
        print(f"Error connecting to S3: {str(e)}")
        return None
    
def create_bucket(s3_client, bucket_name):
    """Create a new S3 bucket"""
    try:
        s3_client.create_bucket(Bucket=bucket_name)
        print(f"Bucket {bucket_name} created successfully")
    except Exception as e:
        print(f"Error creating bucket {bucket_name}: {str(e)}")

def main():
    """Main function to test S3 connection"""
    print("Testing AWS S3 connection...")
    # Create a new S3 bucket
    bucket_name = "avillarreal-resume-portfolio"
    s3_client = connect_to_s3()
    
    create_bucket(s3_client, bucket_name)
    
    if s3_client:
        print("S3 connection successful!")
    else:
        print("S3 connection failed. Please check your credentials and try again.")

if __name__ == "__main__":
    main()
