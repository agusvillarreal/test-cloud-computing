# Healthcare Lab Results Processing Platform - Final Project

## Project Overview

Build a secure healthcare data processing system that ingests lab results from external laboratories, processes and validates them, stores them securely, and provides a patient portal for viewing results.

---

## Learning Objectives

Upon completion, you will demonstrate mastery of:

- **Cloud Architecture Design**: Design multi-tier applications using AWS services
- **Infrastructure as Code**: Provision all infrastructure using Terraform
- **Security Best Practices**: Implement encryption, IAM, network isolation, audit logging
- **Hybrid Architecture**: Make informed decisions about serverless vs container-based compute
- **Data Processing Pipelines**: Build reliable, scalable data ingestion and processing systems
- **CI/CD Implementation**: Automate testing and deployment
- **Cost Awareness**: Understand and optimize AWS costs

---

## Problem Statement

Medical laboratories generate test results daily that need to be:

1. **Ingested** from external lab systems via API
2. **Validated** for data quality and format correctness
3. **Processed** to normalize and enrich the data
4. **Stored** securely with encryption and audit trails
5. **Made available** to patients through a secure web portal
6. **Notified** to patients when results are ready

**Your task:** Build a complete system that handles this workflow using AWS services and infrastructure as code.

---

## Required AWS Services

You **must** use the following services (with architectural justification):

| Service             | Required?          | Use Case                              | Decision Point         |
| ------------------- | ------------------ | ------------------------------------- | ---------------------- |
| **VPC**             | ✅ YES              | Network isolation for healthcare data | No alternatives        |
| **RDS or DynamoDB** | ✅ YES (choose one) | Store patient records and lab results | Justify your choice    |
| **S3**              | ✅ YES              | Store raw files, reports, backups     | No alternatives        |
| **Lambda**          | ✅ YES              | API endpoints, event processing       | For event-driven tasks |
| **ECS or EC2**      | ✅ YES (choose one) | Long-running processors               | Justify your choice    |
| **SQS**             | ✅ YES              | Decouple ingestion from processing    | No alternatives        |
| **API Gateway**     | ✅ YES              | Expose Lambda functions as REST APIs  | No alternatives        |
| **Cognito**         | ✅ YES              | User authentication                   | No alternatives        |
| **CloudWatch**      | ✅ YES              | Logging and monitoring                | No alternatives        |
| **Terraform**       | ✅ YES              | Infrastructure as Code                | No alternatives        |

**Optional but Recommended:**

- SNS for notifications
- EventBridge for scheduled tasks
- CloudFront for CDN
- WAF for additional security
- EBS (only if using EC2)

---

## Architecture Decisions You Must Make

### Decision 1: Database Choice

**Option A: RDS Any engine**

**Option B: DynamoDB**

**You must document:** Why did you choose this database? What are the trade-offs?

### Decision 2: Compute Choice for Processing Workers

**Option A: ECS on EC2**

**Option B: ECS on Fargate**

**Option C: EC2 with custom scripts**

**You must document:** Why did you choose this option? Show cost comparison calculations.

### Decision 3: Authentication Strategy

**Required: Use Cognito** but you can choose:

- User Pools only (simple username/password)
- User Pools + Identity Pools (for direct AWS resource access)
- User Pools + Social Identity Providers (Google, Facebook)

---

## System Components

### 1. Data Ingestion API (Lambda + API Gateway)

**What it does:**

- Receives lab results from external lab systems via POST request
- Validates data format and required fields
- Stores raw data in S3 for compliance
- Sends message to SQS queue for processing
- Returns acknowledgment to caller

**Endpoints required:**

- `POST /api/v1/ingest` - Receive lab result
- `GET /api/v1/health` - Health check
- `GET /api/v1/status/{result_id}` - Check processing status

**Technical requirements:**

- Input validation with proper error messages
- Rate limiting (use API Gateway throttling)
- Audit logging to CloudWatch
- Error handling with appropriate HTTP codes

### 2. Lab Results Processor (ECS or EC2)

**What it does:**

- Polls SQS queue for new lab results
- Retrieves raw data from S3
- Parses and validates medical data
- Normalizes values and flags abnormalities
- Stores processed data in RDS/DynamoDB
- Moves processed files to different S3 prefix
- Triggers notification queue

**Technical requirements:**

- Long polling on SQS (20 second wait time)
- Graceful shutdown handling
- Retry logic for failed processing
- Dead Letter Queue for permanent failures
- CloudWatch metrics for processing rate
- Auto-scaling based on queue depth

### 3. Patient Portal (ECS Fargate or EC2)

**What it does:**

- Web application for patients to view their lab results
- Authentication via Cognito
- Display results with visual indicators for abnormal values
- Generate and download PDF reports
- View processing status

**Pages required:**

- `/login` - Cognito-based authentication
- `/dashboard` - List of all lab results
- `/results/{result_id}` - Detailed view of specific result
- `/profile` - Patient information
- `/health` - ALB health check

**Technical requirements:**

- Secure session management
- HTTPS only -> optional
- Input sanitization
- Responsive design (mobile-friendly)

### 4. Notification Service (Lambda)

**What it does:**

- Triggered by SQS notification queue
- Sends email/SMS when results are ready
- Logs notification delivery status

**Technical requirements:**

- Use SNS or SES for email delivery
- Exponential backoff for retries
- Track delivery status in database

### 5. Report Generation Service (Lambda)

**What it does:**

- Generates PDF reports from lab results
- Stores PDFs in S3 with encryption
- Returns signed URL for download

**Technical requirements:**

- Lambda timeout: 5 minutes minimum
- Memory: 1024 MB minimum
- Store PDFs with patient-specific prefix
- Signed URLs expire in 1 hour

---

## Sample Data Format

### Input Format: Lab Result Ingestion

Use this JSON format for the `POST /api/v1/ingest` endpoint:

json

```json
{
  "patient_id": "P123456",
  "lab_id": "LAB001",
  "lab_name": "Quest Diagnostics",
  "test_type": "complete_blood_count",
  "test_date": "2024-01-15T10:30:00Z",
  "physician": {
    "name": "Dr. Sarah Johnson",
    "npi": "1234567890"
  },
  "results": [
    {
      "test_code": "WBC",
      "test_name": "White Blood Cell Count",
      "value": 7.5,
      "unit": "10^3/uL",
      "reference_range": "4.5-11.0",
      "is_abnormal": false
    },
    {
      "test_code": "RBC",
      "test_name": "Red Blood Cell Count",
      "value": 4.8,
      "unit": "10^6/uL",
      "reference_range": "4.5-5.5",
      "is_abnormal": false
    },
    {
      "test_code": "HGB",
      "test_name": "Hemoglobin",
      "value": 13.2,
      "unit": "g/dL",
      "reference_range": "13.0-17.0",
      "is_abnormal": false
    },
    {
      "test_code": "HCT",
      "test_name": "Hematocrit",
      "value": 39.5,
      "unit": "%",
      "reference_range": "39.0-49.0",
      "is_abnormal": false
    },
    {
      "test_code": "PLT",
      "test_name": "Platelet Count",
      "value": 245,
      "unit": "10^3/uL",
      "reference_range": "150-400",
      "is_abnormal": false
    }
  ],
  "notes": "Fasting sample. Patient reported no recent illness."
}
```

### Additional Test Types Available

#### Complete Metabolic Panel (CMP)

json

```json
{
  "test_type": "complete_metabolic_panel",
  "results": [
    {"test_code": "GLU", "test_name": "Glucose", "value": 95, "unit": "mg/dL", "reference_range": "70-100", "is_abnormal": false},
    {"test_code": "BUN", "test_name": "Blood Urea Nitrogen", "value": 18, "unit": "mg/dL", "reference_range": "7-20", "is_abnormal": false},
    {"test_code": "CREAT", "test_name": "Creatinine", "value": 1.1, "unit": "mg/dL", "reference_range": "0.7-1.3", "is_abnormal": false},
    {"test_code": "NA", "test_name": "Sodium", "value": 140, "unit": "mmol/L", "reference_range": "136-145", "is_abnormal": false},
    {"test_code": "K", "test_name": "Potassium", "value": 4.2, "unit": "mmol/L", "reference_range": "3.5-5.0", "is_abnormal": false},
    {"test_code": "CL", "test_name": "Chloride", "value": 102, "unit": "mmol/L", "reference_range": "98-107", "is_abnormal": false},
    {"test_code": "CO2", "test_name": "Carbon Dioxide", "value": 25, "unit": "mmol/L", "reference_range": "23-29", "is_abnormal": false},
    {"test_code": "CA", "test_name": "Calcium", "value": 9.5, "unit": "mg/dL", "reference_range": "8.5-10.5", "is_abnormal": false}
  ]
}
```

#### Lipid Panel

json

```json
{
  "test_type": "lipid_panel",
  "results": [
    {"test_code": "CHOL", "test_name": "Total Cholesterol", "value": 195, "unit": "mg/dL", "reference_range": "<200", "is_abnormal": false},
    {"test_code": "TRIG", "test_name": "Triglycerides", "value": 120, "unit": "mg/dL", "reference_range": "<150", "is_abnormal": false},
    {"test_code": "HDL", "test_name": "HDL Cholesterol", "value": 55, "unit": "mg/dL", "reference_range": ">40", "is_abnormal": false},
    {"test_code": "LDL", "test_name": "LDL Cholesterol (calc)", "value": 116, "unit": "mg/dL", "reference_range": "<100", "is_abnormal": true},
    {"test_code": "VLDL", "test_name": "VLDL Cholesterol", "value": 24, "unit": "mg/dL", "reference_range": "5-40", "is_abnormal": false}
  ]
}
```

#### Thyroid Function Tests

json

```json
{
  "test_type": "thyroid_panel",
  "results": [
    {"test_code": "TSH", "test_name": "Thyroid Stimulating Hormone", "value": 2.5, "unit": "uIU/mL", "reference_range": "0.4-4.0", "is_abnormal": false},
    {"test_code": "T4", "test_name": "Thyroxine (T4)", "value": 7.8, "unit": "ug/dL", "reference_range": "4.5-12.0", "is_abnormal": false},
    {"test_code": "T3", "test_name": "Triiodothyronine (T3)", "value": 125, "unit": "ng/dL", "reference_range": "80-200", "is_abnormal": false}
  ]
}
```

### Sample Patient Data

Use this for populating your database:

json

```json
[
  {
    "patient_id": "P123456",
    "first_name": "John",
    "last_name": "Smith",
    "date_of_birth": "1985-03-15",
    "email": "john.smith@example.com",
    "phone": "+1-555-0101"
  },
  {
    "patient_id": "P234567",
    "first_name": "Maria",
    "last_name": "Garcia",
    "date_of_birth": "1990-07-22",
    "email": "maria.garcia@example.com",
    "phone": "+1-555-0102"
  },
  {
    "patient_id": "P345678",
    "first_name": "James",
    "last_name": "Wilson",
    "date_of_birth": "1978-11-08",
    "email": "james.wilson@example.com",
    "phone": "+1-555-0103"
  },
  {
    "patient_id": "P456789",
    "first_name": "Li",
    "last_name": "Chen",
    "date_of_birth": "1995-02-14",
    "email": "li.chen@example.com",
    "phone": "+1-555-0104"
  },
  {
    "patient_id": "P567890",
    "first_name": "Sarah",
    "last_name": "Johnson",
    "date_of_birth": "1982-09-30",
    "email": "sarah.johnson@example.com",
    "phone": "+1-555-0105"
  }
]
```

### Data Generator Script

Students can use this Python script to generate test data:

python

```python
#!/usr/bin/env python3
"""
Lab Results Data Generator
Generates realistic lab results for testing
"""

import json
import random
from datetime import datetime, timedelta
import requests

# API endpoint (replace with your API Gateway URL)
API_ENDPOINT = "https://your-api-gateway-url/api/v1/ingest"

PATIENT_IDS = ["P123456", "P234567", "P345678", "P456789", "P567890"]

LAB_SYSTEMS = [
    {"lab_id": "LAB001", "lab_name": "Quest Diagnostics"},
    {"lab_id": "LAB002", "lab_name": "LabCorp"},
    {"lab_id": "LAB003", "lab_name": "Mayo Clinic Labs"}
]

PHYSICIANS = [
    {"name": "Dr. Sarah Johnson", "npi": "1234567890"},
    {"name": "Dr. Michael Chen", "npi": "2345678901"},
    {"name": "Dr. Emily Rodriguez", "npi": "3456789012"}
]

TEST_TEMPLATES = {
    "complete_blood_count": [
        {"test_code": "WBC", "test_name": "White Blood Cell Count", "range": (4.5, 11.0), "unit": "10^3/uL", "ref": "4.5-11.0"},
        {"test_code": "RBC", "test_name": "Red Blood Cell Count", "range": (4.5, 5.5), "unit": "10^6/uL", "ref": "4.5-5.5"},
        {"test_code": "HGB", "test_name": "Hemoglobin", "range": (13.0, 17.0), "unit": "g/dL", "ref": "13.0-17.0"},
        {"test_code": "HCT", "test_name": "Hematocrit", "range": (39.0, 49.0), "unit": "%", "ref": "39.0-49.0"},
        {"test_code": "PLT", "test_name": "Platelet Count", "range": (150, 400), "unit": "10^3/uL", "ref": "150-400"}
    ],
    "complete_metabolic_panel": [
        {"test_code": "GLU", "test_name": "Glucose", "range": (70, 100), "unit": "mg/dL", "ref": "70-100"},
        {"test_code": "BUN", "test_name": "Blood Urea Nitrogen", "range": (7, 20), "unit": "mg/dL", "ref": "7-20"},
        {"test_code": "CREAT", "test_name": "Creatinine", "range": (0.7, 1.3), "unit": "mg/dL", "ref": "0.7-1.3"},
        {"test_code": "NA", "test_name": "Sodium", "range": (136, 145), "unit": "mmol/L", "ref": "136-145"},
        {"test_code": "K", "test_name": "Potassium", "range": (3.5, 5.0), "unit": "mmol/L", "ref": "3.5-5.0"}
    ],
    "lipid_panel": [
        {"test_code": "CHOL", "test_name": "Total Cholesterol", "range": (150, 220), "unit": "mg/dL", "ref": "<200"},
        {"test_code": "TRIG", "test_name": "Triglycerides", "range": (80, 170), "unit": "mg/dL", "ref": "<150"},
        {"test_code": "HDL", "test_name": "HDL Cholesterol", "range": (40, 70), "unit": "mg/dL", "ref": ">40"},
        {"test_code": "LDL", "test_name": "LDL Cholesterol", "range": (80, 130), "unit": "mg/dL", "ref": "<100"}
    ],
    "thyroid_panel": [
        {"test_code": "TSH", "test_name": "Thyroid Stimulating Hormone", "range": (0.4, 4.0), "unit": "uIU/mL", "ref": "0.4-4.0"},
        {"test_code": "T4", "test_name": "Thyroxine (T4)", "range": (4.5, 12.0), "unit": "ug/dL", "ref": "4.5-12.0"},
        {"test_code": "T3", "test_name": "Triiodothyronine (T3)", "range": (80, 200), "unit": "ng/dL", "ref": "80-200"}
    ]
}

def generate_result(template):
    """Generate a single test result with some chance of abnormality"""
    # 80% chance of normal, 20% chance of abnormal
    if random.random() < 0.8:
        value = round(random.uniform(template["range"][0], template["range"][1]), 1)
        is_abnormal = False
    else:
        # Generate abnormal value (outside range)
        if random.random() < 0.5:
            value = round(random.uniform(template["range"][0] * 0.7, template["range"][0]), 1)
        else:
            value = round(random.uniform(template["range"][1], template["range"][1] * 1.3), 1)
        is_abnormal = True
    
    return {
        "test_code": template["test_code"],
        "test_name": template["test_name"],
        "value": value,
        "unit": template["unit"],
        "reference_range": template["ref"],
        "is_abnormal": is_abnormal
    }

def generate_lab_result():
    """Generate a complete lab result"""
    patient_id = random.choice(PATIENT_IDS)
    lab = random.choice(LAB_SYSTEMS)
    physician = random.choice(PHYSICIANS)
    test_type = random.choice(list(TEST_TEMPLATES.keys()))
    
    # Generate test date within last 30 days
    days_ago = random.randint(0, 30)
    test_date = datetime.now() - timedelta(days=days_ago)
    
    results = [generate_result(template) for template in TEST_TEMPLATES[test_type]]
    
    return {
        "patient_id": patient_id,
        "lab_id": lab["lab_id"],
        "lab_name": lab["lab_name"],
        "test_type": test_type,
        "test_date": test_date.isoformat(),
        "physician": physician,
        "results": results,
        "notes": random.choice([
            "Fasting sample. Patient reported no recent illness.",
            "Non-fasting sample.",
            "Patient reported taking medications as prescribed.",
            "Follow-up test as recommended.",
            "Annual wellness check."
        ])
    }

def send_to_api(data):
    """Send lab result to API"""
    try:
        response = requests.post(
            API_ENDPOINT,
            json=data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error sending data: {e}")
        return None

def main():
    """Generate and send test data"""
    print("Healthcare Lab Results Data Generator")
    print("=" * 50)
    
    num_results = int(input("How many lab results to generate? "))
    
    for i in range(num_results):
        result = generate_lab_result()
        
        print(f"\n[{i+1}/{num_results}] Generating result for patient {result['patient_id']}")
        print(f"  Test Type: {result['test_type']}")
        
        # Optionally send to API
        send = input("  Send to API? (y/n): ").lower()
        
        if send == 'y':
            response = send_to_api(result)
            if response:
                print(f"  ✓ Sent successfully. Result ID: {response.get('result_id', 'N/A')}")
            else:
                print("  ✗ Failed to send")
        else:
            # Just save to file
            filename = f"lab_result_{i+1}.json"
            with open(filename, 'w') as f:
                json.dump(result, f, indent=2)
            print(f"  ✓ Saved to {filename}")
    
    print("\n" + "=" * 50)
    print("Data generation complete!")

if __name__ == "__main__":
    main()
```

---

## Required Deliverables

### 1. Source Code Repository

**Structure:**

```
healthcare-lab-platform/
├── README.md                    # Project overview and setup
├── ARCHITECTURE.md              # Architecture decisions and diagrams
├── terraform/                   # All Terraform code
│   ├── main.tf
│   ├── vpc.tf
│   ├── rds.tf (or dynamodb.tf)
│   ├── ecs.tf (or ec2.tf)
│   ├── lambda.tf
│   ├── cognito.tf
│   ├── s3.tf
│   ├── sqs.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── lambda/                      # Lambda function code
│   ├── ingest/
│   ├── notify/
│   └── report/
├── services/                    # ECS/EC2 services
│   ├── processor/
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── worker.py
│   └── portal/
│       ├── Dockerfile
│       ├── requirements.txt
│       └── app.py
├── scripts/                     # Utility scripts
│   ├── data_generator.py
│   ├── setup_database.sql
│   └── test_api.sh
├── tests/                       # Test files
│   ├── unit/
│   └── integration/
├── .github/                     # CI/CD workflows
│   └── workflows/
│       └── deploy.yml
└── docs/                        # Documentation
    ├── setup.md
    ├── api.md
    └── cost_analysis.md
```

### 2. Infrastructure Documentation (ARCHITECTURE.md)

**Must include:**

1. **Architecture Diagram**
    - Hand-drawn or using Draw.io/Lucidchart
    - Show all AWS services and their connections
    - Network boundaries

2. **Technology Decisions**

markdown

```markdown
   ### Database Choice: [RDS/DynamoDB]
   
   **Decision:** We chose [X] because...
   
   **Trade-offs considered:**
   - Option A: [Pros and cons]
   - Option B: [Pros and cons]
   
   **Cost comparison:** 
   - RDS: $X/month
   - DynamoDB: $Y/month
   
   **Final justification:** ...
```

3. **Data Flow Documentation**
    - Step-by-step flow from ingestion to patient viewing
    - Include error handling paths
    - Document retry mechanisms

4. **Security Model**
    - How is data encrypted?
    - How are credentials managed?
    - What IAM roles exist and why?
    - Network isolation strategy

### 3. Terraform Code

**Must be:**

- Modular (use modules where appropriate)
- Documented with comments
- Use variables for all configurable values
- Include outputs for important resources
- Pass `terraform validate`
- Pass `terraform fmt -check`

**Required resources:**

- VPC with public/private subnets
- Security groups with least privilege
- Database (RDS or DynamoDB)
- S3 buckets with encryption
- Lambda functions with proper IAM roles
- ECS cluster or EC2 instances
- SQS queues with DLQ
- API Gateway
- Cognito User Pool
- CloudWatch log groups

### 4. Working Application

**Functional Requirements:**

- [ ]  API accepts lab results via POST request
- [ ]  Data is validated before processing
- [ ]  Raw data stored in S3
- [ ]  Processing worker retrieves from queue
- [ ]  Processed data stored in database
- [ ]  Patient can log in via Cognito
- [ ]  Patient can view list of results
- [ ]  Patient can view detailed result
- [ ]  Patient can download PDF report
- [ ]  System handles errors gracefully
- [ ]  All components log to CloudWatch


### 5. CI/CD Pipeline

**Minimum requirements:**

- Automated testing on pull requests
- Automated deployment to staging on merge to `develop`
- Manual approval for production deployment
- Terraform plan runs before apply
- Docker images built and pushed to ECR
- Lambda functions packaged and deployed

### 6. Documentation

**README.md must include:**

- Project description
- Prerequisites
- Setup instructions
- How to deploy infrastructure
- How to run locally
- How to test
- Cost estimates
- Known limitations

**API Documentation (docs/api.md):**

- All endpoints
- Request/response formats
- Authentication requirements
- Error codes
- Example requests using curl

**Cost Analysis (docs/cost_analysis.md):**

- Estimated monthly cost breakdown
- Cost per lab result processed
- Optimization strategies implemented
- Further optimization opportunities


---

## Grading Rubric (100 points)

### Infrastructure (25 points)

|Criteria|Points|Description|
|---|---|---|
|**Terraform Quality**|10|Code is modular, documented, follows best practices|
|**Network Design**|5|VPC properly configured with public/private subnets|
|**Security Implementation**|5|Encryption, IAM, security groups properly configured|
|**Resource Organization**|5|Proper tagging, naming conventions, resource groups|

### Application Development (25 points)

|Criteria|Points|Description|
|---|---|---|
|**Code Quality**|8|Clean, readable, follows language conventions|
|**Error Handling**|5|Proper error handling and logging throughout|
|**Data Processing**|7|Correct parsing, validation, and storage of lab results|
|**Portal Functionality**|5|All required pages work correctly|

### Architecture & Design (20 points)

|Criteria|Points|Description|
|---|---|---|
|**Technology Choices**|8|Well-justified decisions with trade-off analysis|
|**Scalability**|6|System can handle increased load|
|**Reliability**|6|Proper error handling, retries, DLQ implementation|

### Security & Compliance (15 points)

|Criteria|Points|Description|
|---|---|---|
|**Data Encryption**|5|Data encrypted at rest and in transit|
|**Access Control**|5|Proper IAM roles with least privilege|
|**Audit Logging**|5|All actions logged for compliance|

### CI/CD & DevOps (10 points)

|Criteria|Points|Description|
|---|---|---|
|**Pipeline Implementation**|5|Automated testing and deployment|
|**Testing**|5|Unit and integration tests implemented|

### Documentation (5 points)

|Criteria|Points|Description|
|---|---|---|
|**Completeness**|3|All required docs present and complete|
|**Clarity**|2|Documentation is clear and useful|