import boto3

ec2 = boto3.client('ec2')

response = ec2.run_instances(
    ImageId='ami-0c55b159cbfafe1f0',
    InstanceType='t2.micro',
    KeyName='my-key-pair',
    SecurityGroupIds=['sg-0c55b159cbfafe1f0'],
    SubnetId='subnet-0c55b159cbfafe1f0',
)
print(response)
