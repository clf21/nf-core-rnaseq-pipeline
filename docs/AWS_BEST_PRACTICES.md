# AWS Best Practices for nf-core RNA-seq

## Cost Optimization

### Use Spot Instances
Spot instances can reduce costs by 70-90% compared to on-demand. Our configurations use SPOT_CAPACITY_OPTIMIZED strategy.

```groovy
// In nextflow.config (already configured)
computeResources {
    type: "SPOT"
    allocationStrategy: "SPOT_CAPACITY_OPTIMIZED"
}
```

### Choose Right Instance Types
Let AWS Batch select optimal instances automatically:
```groovy
instanceTypes: ["optimal"]
```

For RNA-seq, this typically selects:
- **FastQC/Trimming**: c5.xlarge, c5.2xlarge (compute-optimized)
- **STAR alignment**: r5.4xlarge, r5.8xlarge (memory-optimized, 32-64GB)
- **Salmon**: c5.2xlarge (compute-optimized)

### Set Auto-scaling Limits

**Small datasets (< 50 samples):**
```groovy
minvCpus: 0
maxvCpus: 128
desiredvCpus: 0
```

**Large datasets (50-500 samples):**
```groovy
minvCpus: 0
maxvCpus: 256
desiredvCpus: 0
```

**Very large datasets (500-2000 samples):**
```groovy
minvCpus: 0
maxvCpus: 512
desiredvCpus: 0
```

Setting `minvCpus: 0` ensures you pay nothing when idle.

### S3 Storage Optimization

**During Analysis:**
- Use S3 Standard for work directory (frequent access)
- Pipeline automatically cleans up intermediate files

**After Completion:**
- Move results to S3 Standard-IA (Infrequent Access) after 30 days
- Archive to Glacier for long-term storage

**S3 Lifecycle Policy Example:**
```bash
aws s3api put-bucket-lifecycle-configuration \
    --bucket your-bucket \
    --lifecycle-configuration file://lifecycle.json
```

`lifecycle.json`:
```json
{
  "Rules": [
    {
      "Id": "ArchiveRNAseqResults",
      "Status": "Enabled",
      "Prefix": "results/",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ]
    },
    {
      "Id": "DeleteWorkDirectory",
      "Status": "Enabled",
      "Prefix": "work/",
      "Expiration": {
        "Days": 7
      }
    }
  ]
}
```

## Performance Optimization

### Parallelization Strategy

**Key Principle**: Maximize parallel execution while staying within AWS Batch limits.

1. **Process-level parallelization**: Each sample runs independently
2. **Task-level parallelization**: Multi-threaded tools (STAR, Salmon)
3. **Queue throttling**: Prevent API rate limits

```groovy
// In aws_large_scale.config
executor {
    queueSize = 1000              // Max concurrent jobs
    submitRateLimit = '50/1min'   // API rate limit
}
```

### Resource Allocation

**Memory Guidelines:**
- **STAR**: 10x genome size (human: ~30GB, mouse: ~25GB)
- **Salmon**: 8-16GB per sample
- **MultiQC**: Scales with sample count (~1GB per 100 samples)

**CPU Guidelines:**
- **STAR**: 8-16 cores optimal
- **Salmon**: 4-8 cores optimal
- **FastQC/Trimming**: 2-4 cores sufficient

### Retry Strategy

Configure intelligent retries for transient failures:

```groovy
process {
    errorStrategy = { task.exitStatus in [143,137,104,134,139] ? 'retry' : 'finish' }
    maxRetries = 3
    
    // Increase resources on retry
    memory = { check_max(16.GB * task.attempt, 'memory') }
}
```

Common error codes:
- **137**: Out of memory (killed by OOM)
- **143**: Timeout or terminated
- **139**: Segmentation fault

## Data Management

### Input Data Location

**Best Practice**: Store FASTQ files in S3 same region as Batch

```csv
sample,fastq_1,fastq_2,strandedness
S1,s3://bucket/fastq/S1_R1.fq.gz,s3://bucket/fastq/S1_R2.fq.gz,reverse
```

**Benefits:**
- No data transfer costs within region
- Faster data access
- Direct S3 streaming (no copying to EBS)

### Output Organization

```
s3://bucket/
├── work/                    # Temporary (delete after completion)
├── results/
│   └── project_name/
│       ├── multiqc/
│       ├── star_salmon/
│       └── pipeline_info/
└── archive/                 # Long-term storage
```

### Downloading Results

**Selective download** (recommended):
```bash
# Just count matrices
aws s3 cp s3://bucket/results/star_salmon/salmon.merged.gene_counts.tsv ./

# Just reports
aws s3 sync s3://bucket/results/multiqc/ ./reports/ --exclude "*" --include "*.html"
```

**Full download**:
```bash
aws s3 sync s3://bucket/results/ ./local_results/
```

## Security Best Practices

### IAM Permissions

**Minimum required permissions:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "batch:DescribeJobQueues",
        "batch:DescribeJobs",
        "batch:SubmitJob",
        "batch:TerminateJob"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket",
        "arn:aws:s3:::your-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

### Encrypt Data

```bash
# Enable S3 encryption
aws s3api put-bucket-encryption \
    --bucket your-bucket \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'
```

## Monitoring and Debugging

### CloudWatch Logs

**View logs for a specific job:**
```bash
JOB_ID="your-job-id"
aws batch describe-jobs --jobs $JOB_ID

# Get log stream
LOG_STREAM=$(aws batch describe-jobs --jobs $JOB_ID \
    --query 'jobs[0].container.logStreamName' --output text)

# View logs
aws logs get-log-events \
    --log-group-name /aws/batch/job \
    --log-stream-name $LOG_STREAM
```

### Nextflow Tower

Free monitoring and visualization:

```bash
export TOWER_ACCESS_TOKEN=your-token
nextflow run nf-core/rnaseq -with-tower ...
```

**Benefits:**
- Real-time pipeline monitoring
- Resource usage graphs
- Task execution timeline
- Easy debugging

### Cost Tracking

**Tag your resources:**
```groovy
// In nextflow.config
aws {
    batch {
        jobRole = 'arn:aws:iam::account:role/BatchJobRole'
        volumes = '/tmp'
        tags = [
            Project: 'RNAseq-Analysis',
            Owner: 'chris.frank',
            CostCenter: '12345'
        ]
    }
}
```

**Monitor costs:**
```bash
# Get cost breakdown
aws ce get-cost-and-usage \
    --time-period Start=2024-01-01,End=2024-01-31 \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --group-by Type=TAG,Key=Project
```

## Troubleshooting

### Common Issues

**1. Jobs stuck in RUNNABLE**
```bash
# Check compute environment
aws batch describe-compute-environments \
    --compute-environments nf-core-rnaseq-compute-env

# Likely causes:
# - No capacity in compute environment
# - VPC/subnet misconfiguration
# - Service limits reached
```

**2. Out of memory errors**
```bash
# Increase memory allocation
# Edit nextflow.config:
process {
    withName: 'STAR_ALIGN' {
        memory = { check_max(64.GB * task.attempt, 'memory') }
    }
}
```

**3. Slow data transfer**
```bash
# Ensure FASTQ files are in same region
aws s3 ls s3://your-bucket --region us-east-1

# Use VPC endpoints for S3 (no data transfer charges)
aws ec2 create-vpc-endpoint \
    --vpc-id vpc-xxxx \
    --service-name com.amazonaws.us-east-1.s3
```

### Performance Profiling

**Check resource usage:**
```bash
# View execution report
open results/pipeline_info/execution_report.html

# Examine trace file
cat results/pipeline_info/execution_trace.txt | \
    awk -F'\t' '{print $2, $5, $6, $7}' | \
    sort -k2 -nr | head -20
```

## Cost Estimation

**Approximate costs (using Spot instances):**

| Samples | Genome | Spot Cost | On-Demand Cost | Time |
|---------|--------|-----------|----------------|------|
| 10 | Human | $5 | $15 | 3h |
| 50 | Human | $25 | $80 | 5h |
| 100 | Human | $50 | $150 | 7h |
| 500 | Human | $200 | $700 | 10h |
| 1000 | Human | $400 | $1,400 | 12h |

**Additional costs:**
- S3 storage: ~$0.023/GB/month (Standard)
- Data transfer: Free within region
- CloudWatch Logs: ~$0.50/GB ingested

**Cost factors:**
- Read depth (higher = more expensive)
- Genome size (human > mouse)
- Number of samples
- Instance type availability

## Checklist for Production

- [ ] Compute environment configured with Spot instances
- [ ] VPC endpoints configured for S3 (optional, saves transfer costs)
- [ ] IAM roles properly configured
- [ ] S3 bucket lifecycle policies set
- [ ] CloudWatch log retention configured (7-30 days)
- [ ] Resource limits tuned for dataset size
- [ ] Cost allocation tags applied
- [ ] Monitoring set up (Tower or CloudWatch)
- [ ] Backup strategy defined for results
- [ ] Documentation of strandedness and parameters

## Additional Resources

- [AWS Batch Best Practices](https://docs.aws.amazon.com/batch/latest/userguide/best-practices.html)
- [Nextflow on AWS](https://www.nextflow.io/docs/latest/awscloud.html)
- [nf-core AWS Guide](https://nf-co.re/docs/usage/tutorials/aws_batch)
- [AWS Cost Optimization](https://aws.amazon.com/aws-cost-management/)

---

**Questions?** Check the main [README.md](../README.md) or ask in nf-core Slack.
