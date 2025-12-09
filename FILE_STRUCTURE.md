# File Structure

```
nf-core-rnaseq-pipeline/
│
├── nextflow.config                              # Main Nextflow configuration
│                                                # - Local and AWS execution profiles
│                                                # - Resource limits and retry strategies
│                                                # - Pipeline parameters
│
├── README.md                                    # Comprehensive user documentation
├── PIPELINE_SUMMARY.md                          # Quick reference summary
│
├── configs/                                     # Additional configuration files
│   ├── genomes.config                          # Reference genome specifications
│   │                                            # - GRCh38, GRCm39 iGenomes paths
│   │                                            # - Custom genome template
│   └── aws_large_scale.config                  # AWS optimization for 100-2000 samples
│                                                # - Increased parallelization
│                                                # - Process-specific resources
│
├── samplesheets/                               # Sample metadata templates
│   ├── samplesheet_paired_end_template.csv     # Template for paired-end reads
│   ├── samplesheet_single_end_template.csv     # Template for single-end reads
│   ├── example_human_GRCh38.csv                # Human samples example
│   └── example_mouse_GRCm39.csv                # Mouse samples example
│
├── scripts/                                     # Helper scripts
│   ├── generate_samplesheet.py                 # Auto-generate samplesheet from FASTQ dir
│   │                                            # - Auto-detects paired-end vs single-end
│   │                                            # - S3 path conversion
│   ├── setup_aws_batch.sh                      # One-time AWS Batch infrastructure setup
│   │                                            # - Creates IAM roles
│   │                                            # - Configures compute environment
│   │                                            # - Creates job queue
│   ├── run_local.sh                            # Wrapper for local execution
│   │                                            # - Docker-based
│   │                                            # - 2-10 samples
│   └── run_aws.sh                              # Wrapper for AWS Batch execution
│                                                # - 2-2000 samples
│                                                # - Auto-scaling
│
└── docs/                                        # Additional documentation
    ├── QUICKSTART.md                           # Get started in 5 minutes
    ├── AWS_BEST_PRACTICES.md                   # Cost optimization and performance tuning
    │                                            # - Spot instances
    │                                            # - Resource allocation
    │                                            # - Monitoring strategies
    └── downstream_analysis_example.R           # DESeq2 differential expression template
                                                 # - Import Salmon data with tximport
                                                 # - Run DESeq2
                                                 # - Generate visualizations

```

## File Descriptions

### Configuration Files

**nextflow.config**
- Main configuration with profiles: `local`, `aws`, `aws_large_scale`
- Global parameters: genome, strandedness, aligner
- Resource limits: max_cpus, max_memory, max_time
- Execution tracking: timeline, report, trace

**configs/genomes.config**
- Pre-configured iGenomes references for GRCh38 and GRCm39
- Template for custom genome configuration
- Paths to FASTA, GTF, and pre-built indices

**configs/aws_large_scale.config**
- Optimized for 100-2000 samples
- Aggressive parallelization (1000 concurrent jobs)
- Process-specific resource allocations
- Enhanced retry strategies

### Samplesheet Templates

**Format:**
```csv
sample,fastq_1,fastq_2,strandedness
SAMPLE_NAME,path/to/R1.fastq.gz,path/to/R2.fastq.gz,reverse
```

**Fields:**
- `sample`: Unique sample identifier
- `fastq_1`: Path to forward reads (or only reads for single-end)
- `fastq_2`: Path to reverse reads (empty for single-end)
- `strandedness`: auto|unstranded|forward|reverse

### Scripts

**generate_samplesheet.py**
```bash
Usage: python generate_samplesheet.py \
    --input_dir /path/to/fastq/ \
    --output samplesheet.csv \
    --strandedness reverse
```

**setup_aws_batch.sh**
```bash
# Interactive setup wizard
./scripts/setup_aws_batch.sh

# Creates:
# - IAM roles (AWSBatchServiceRole, ecsInstanceRole)
# - Compute environment (Spot instances)
# - Job queue
# - S3 bucket for work files
```

**run_local.sh**
```bash
Usage: ./scripts/run_local.sh \
    -i samplesheet.csv \
    -g GRCh38 \
    -o results/
```

**run_aws.sh**
```bash
Usage: ./scripts/run_aws.sh \
    -i samplesheet.csv \
    -g GRCh38 \
    -o s3://bucket/results \
    -p aws_large_scale
```

### Documentation

**README.md** - Main documentation covering:
- Installation and setup
- Usage examples
- Configuration options
- Output structure
- Troubleshooting

**QUICKSTART.md** - Fast start guide:
- Minimal setup steps
- Test run instructions
- Common commands
- Quick troubleshooting

**AWS_BEST_PRACTICES.md** - Production AWS deployment:
- Cost optimization strategies
- Performance tuning
- Security best practices
- Monitoring and debugging
- Cost estimation tables

**downstream_analysis_example.R** - Complete R analysis pipeline:
- Import Salmon quantification
- DESeq2 differential expression
- Visualizations (PCA, volcano, heatmap)
- Gene set enrichment analysis setup

## Key Features by File

| File | Key Features |
|------|-------------|
| nextflow.config | 3 execution profiles, resource management, reproducibility tracking |
| genomes.config | 4 pre-configured genomes, custom genome support |
| aws_large_scale.config | 1000 job parallelization, optimized retries |
| generate_samplesheet.py | Auto-detection, batch processing, S3 integration |
| setup_aws_batch.sh | Interactive wizard, one-command setup |
| run_local.sh | Simple interface, auto-scaling resources |
| run_aws.sh | Multi-profile support, S3 integration |
| QUICKSTART.md | 5-minute setup, common commands |
| AWS_BEST_PRACTICES.md | Cost tables, security configs |
| downstream_analysis_example.R | Complete DE workflow, visualization |

## Workflow Overview

```
1. Setup
   ├── Install Nextflow + Docker (local)
   └── Run setup_aws_batch.sh (AWS)

2. Prepare Data
   ├── Organize FASTQ files
   └── Generate samplesheet
       └── python scripts/generate_samplesheet.py

3. Execute Pipeline
   ├── Local: ./scripts/run_local.sh
   └── AWS: ./scripts/run_aws.sh

4. Review Results
   ├── MultiQC report: results/multiqc/
   └── Gene counts: results/star_salmon/

5. Downstream Analysis
   └── R: docs/downstream_analysis_example.R
```

## Customization Points

1. **Genome References**: Edit `configs/genomes.config`
2. **Resource Limits**: Edit `nextflow.config` params section
3. **AWS Configuration**: Edit `nextflow.config` aws profile
4. **Process Resources**: Edit `configs/aws_large_scale.config`
5. **Pipeline Parameters**: Pass via command line or edit nextflow.config

## Size and Complexity

| Category | Count | Total Lines |
|----------|-------|------------|
| Config files | 3 | ~400 |
| Samplesheets | 4 templates | ~30 |
| Scripts | 4 | ~800 |
| Documentation | 5 | ~2000 |
| **Total** | **16 files** | **~3230 lines** |

---

All scripts are executable. All configs are version-controlled and production-ready.
