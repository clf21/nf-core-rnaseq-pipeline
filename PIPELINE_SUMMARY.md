# Pipeline Summary

## Overview

This nf-core RNA-seq pipeline setup provides a production-ready workflow for processing bulk RNA-seq data from raw FASTQ files to gene and transcript-level count matrices.

## What This Setup Provides

### 1. Configuration Files
- **nextflow.config**: Main configuration with local and AWS profiles
- **configs/aws_large_scale.config**: Optimized for 100-2000 samples
- **configs/genomes.config**: Reference genome specifications

### 2. Sample Management
- **Samplesheet templates**: For single-end and paired-end data
- **Example samplesheets**: Human (GRCh38) and mouse (GRCm39)
- **Auto-generation script**: Create samplesheets from FASTQ directories

### 3. Execution Scripts
- **run_local.sh**: Wrapper for local execution
- **run_aws.sh**: Wrapper for AWS Batch execution
- **setup_aws_batch.sh**: One-time AWS infrastructure setup

### 4. Documentation
- **README.md**: Comprehensive user guide
- **QUICKSTART.md**: Get started in 5 minutes
- **AWS_BEST_PRACTICES.md**: Cost optimization and performance tuning
- **downstream_analysis_example.R**: DESeq2 analysis template

## Pipeline Workflow

```
Input: FASTQ files + Samplesheet CSV
  ↓
FastQC (quality metrics)
  ↓
TrimGalore (adapter trimming)
  ↓
STAR (genome alignment)
  ↓
Salmon (transcript quantification)
  ↓
MultiQC (aggregate QC report)
  ↓
Output: BAM files + Count matrices + QC reports
```

## Key Features

### Scalability
- **Local**: 2-10 samples on laptop/workstation
- **AWS Small**: 10-100 samples
- **AWS Large**: 100-2000 samples with optimized parallelization

### Flexibility
- **Single or paired-end**: Auto-detected from samplesheet
- **Strandedness**: User-configurable or auto-detected
- **Genome**: Pre-configured for human/mouse, supports custom genomes
- **Aligner options**: STAR+Salmon (default), STAR+RSEM, HISAT2

### Reproducibility
- **Versioned pipeline**: nf-core/rnaseq v3.14.0
- **Containerized**: All tools in Docker/Singularity containers
- **Config-driven**: Parameters stored in version-controlled configs
- **Execution reports**: Automatic timeline, resource usage tracking

## Output Files

### Primary Outputs

**Gene-level counts** (for DESeq2, edgeR):
```
results/star_salmon/salmon.merged.gene_counts.tsv
```

**Transcript-level counts** (for sleuth, tximport):
```
results/star_salmon/salmon.merged.transcript_counts.tsv
```

**QC report** (summary of all samples):
```
results/multiqc/star_salmon/multiqc_report.html
```

### Secondary Outputs

- **BAM files**: `results/star_salmon/*.bam`
- **Individual sample counts**: `results/star_salmon/*/quant.sf`
- **FastQC reports**: `results/fastqc/`
- **Execution metrics**: `results/pipeline_info/`

## Supported Genomes

### Pre-configured (via iGenomes)
- **GRCh38** (human, NCBI annotation)
- **GRCh38_ensembl** (human, Ensembl annotation)
- **GRCm39** (mouse, latest Ensembl)
- **GRCm38** (mouse, mm10 equivalent)

### Custom Genomes
Provide:
- Reference FASTA
- Gene annotation GTF
- Optional: STAR index, Salmon index (built if not provided)

## Computational Requirements

### Local Execution
**Minimum:**
- 4 CPU cores
- 16 GB RAM
- 100 GB disk space
- Docker installed

**Recommended:**
- 8-16 CPU cores
- 32-64 GB RAM
- 500 GB disk space (more for many samples)
- SSD for improved I/O

### AWS Execution
**Infrastructure:**
- AWS Batch compute environment (Spot instances)
- S3 bucket for work directory and results
- VPC with subnets (default VPC works)
- IAM roles for Batch and EC2

**Auto-scaling:**
- Scales from 0 to 256+ vCPUs based on workload
- STAR alignment requires ~32 GB RAM per sample
- Uses mix of compute and memory-optimized instances

## Processing Time

### Local (8 cores, 32GB RAM)
- 2 samples: ~4 hours
- 5 samples: ~8 hours
- 10 samples: ~16 hours

### AWS (auto-scaled)
- 10 samples: ~2-3 hours
- 50 samples: ~4-5 hours
- 100 samples: ~6-8 hours
- 500 samples: ~10-12 hours

Time varies with:
- Read depth (20M vs 50M reads/sample)
- Genome size (mouse faster than human)
- Instance availability

## Cost Estimation (AWS Spot)

| Samples | Approx. Cost | Time |
|---------|-------------|------|
| 10 | $5-10 | 3h |
| 50 | $25-40 | 5h |
| 100 | $50-80 | 7h |
| 500 | $200-300 | 10h |

Includes:
- EC2 Spot instance compute
- S3 storage (work + results)
- Data transfer within region (free)

Not included:
- Long-term S3 storage
- Data transfer out of AWS
- CloudWatch logs (minimal)

## Pipeline Parameters

### Essential
```bash
--input           # Path to samplesheet CSV
--genome          # Genome assembly (GRCh38, GRCm39, etc.)
--outdir          # Output directory path
```

### Common
```bash
--strandedness    # auto, unstranded, forward, reverse
--aligner         # star_salmon (default), star_rsem, hisat2
--trimmer         # trimgalore (default), fastp
--skip_trimming   # Skip adapter trimming
```

### Resource Limits
```bash
--max_cpus        # Maximum CPU cores per process
--max_memory      # Maximum memory per process
--max_time        # Maximum time per process
```

### Save Options
```bash
--save_reference        # Save reference indices
--save_trimmed         # Save trimmed FASTQ files
--save_align_intermeds # Save intermediate BAM files
--save_unaligned       # Save unaligned reads
```

## Quality Control Metrics

### MultiQC Report Includes:
- **FastQC**: Per-base quality, sequence duplication, adapter content
- **TrimGalore**: Trimming statistics
- **STAR**: Alignment rates, unique vs multi-mapped reads
- **Salmon**: Mapping rates, library type detection
- **RSeQC**: Gene body coverage, read distribution
- **Picard**: RNA-seq metrics, duplication rates

### Key Metrics to Check:
1. **% Aligned**: Should be > 70% for good quality
2. **% Duplicates**: High in RNA-seq (10-50% normal)
3. **% Genes Detected**: Typical 10,000-15,000 for human
4. **Strandedness**: Should match library prep
5. **3' bias**: Should be minimal for good libraries

## Downstream Analysis

### Import into R (with tximport)
```R
library(tximport)
library(DESeq2)

# Import Salmon data
txi <- tximport(files, type = "salmon", tx2gene = tx2gene)

# Create DESeq2 object
dds <- DESeqDataSetFromTximport(txi, colData, design = ~ condition)
```

### Alternative: Direct count import
```R
counts <- read.table("salmon.merged.gene_counts.tsv", 
                     header = TRUE, row.names = 1)
```

### Compatible Tools:
- **DESeq2**: Differential expression (recommended)
- **edgeR**: Differential expression
- **limma-voom**: Differential expression
- **sleuth**: Transcript-level analysis
- **clusterProfiler**: Gene set enrichment
- **WGCNA**: Co-expression networks

## File Organization

```
nf-core-rnaseq-pipeline/
├── nextflow.config              # Main configuration
├── configs/                     # Additional configs
│   ├── genomes.config
│   └── aws_large_scale.config
├── samplesheets/               # Templates and examples
│   ├── samplesheet_paired_end_template.csv
│   ├── samplesheet_single_end_template.csv
│   ├── example_human_GRCh38.csv
│   └── example_mouse_GRCm39.csv
├── scripts/                    # Helper scripts
│   ├── generate_samplesheet.py
│   ├── setup_aws_batch.sh
│   ├── run_local.sh
│   └── run_aws.sh
├── docs/                       # Documentation
│   ├── QUICKSTART.md
│   ├── AWS_BEST_PRACTICES.md
│   └── downstream_analysis_example.R
└── README.md                   # Main documentation
```

## Common Workflows

### Typical Local Workflow
1. Organize FASTQ files in directory
2. Generate samplesheet: `python scripts/generate_samplesheet.py`
3. Run pipeline: `./scripts/run_local.sh -i samplesheet.csv -g GRCh38 -o results/`
4. Review MultiQC report
5. Import counts into R for DE analysis

### Typical AWS Workflow
1. Upload FASTQ files to S3
2. Setup AWS Batch: `./scripts/setup_aws_batch.sh`
3. Update nextflow.config with Batch queue
4. Create samplesheet with S3 paths
5. Run pipeline: `./scripts/run_aws.sh -i samplesheet.csv -g GRCh38 -o s3://bucket/results`
6. Download results from S3
7. Analyze with downstream tools

## Troubleshooting Resources

### Pipeline Issues
- Check: `results/pipeline_info/execution_report.html`
- Logs: `work/<task-hash>/.command.log`
- Resume: Add `-resume` flag to continue from failure

### Memory Issues
- Increase `--max_memory`
- Or edit process-specific memory in nextflow.config

### AWS Issues
- Check CloudWatch Logs
- Verify IAM permissions
- Ensure VPC/subnet configuration correct
- Monitor AWS Batch console

## Additional Resources

### Official Documentation
- nf-core/rnaseq: https://nf-co.re/rnaseq
- Nextflow: https://www.nextflow.io/docs/
- AWS Batch: https://docs.aws.amazon.com/batch/

### Community Support
- nf-core Slack: https://nf-co.re/join
- Nextflow Gitter: https://gitter.im/nextflow-io/nextflow
- GitHub Issues: https://github.com/nf-core/rnaseq/issues

### Learning Materials
- nf-core tutorials: https://nf-co.re/usage/tutorials
- Nextflow training: https://training.nextflow.io/
- RNA-seq analysis course: https://bioinformatics-core-shared-training.github.io/

## Version Information

- **Pipeline**: nf-core/rnaseq v3.14.0
- **Nextflow**: ≥23.04.0 required
- **Configuration**: v1.0.0
- **Last Updated**: December 2024

## Citation

If you use this pipeline, please cite:

**nf-core/rnaseq:**
Patel H, Ewels P, Peltzer A, et al. nf-core/rnaseq: RNA sequencing analysis pipeline using STAR, RSEM, HISAT2 or Salmon with gene/isoform counts and extensive quality control. Zenodo. doi:10.5281/zenodo.1400710

**Nextflow:**
Di Tommaso P, Chatzou M, Floden EW, Barja PP, Palumbo E, Notredame C. Nextflow enables reproducible computational workflows. Nat Biotechnol. 2017;35(4):316-319. doi:10.1038/nbt.3820

---

For detailed usage instructions, see [README.md](README.md)
