# nf-core RNA-seq Pipeline Setup

Containerized bioinformatics pipeline for processing RNA-seq data from raw FASTQ files to gene and transcript-level count matrices. Built on the [nf-core/rnaseq](https://nf-co.re/rnaseq) pipeline with support for local and AWS cloud execution.

## Features

✨ **Flexible Execution**: Run locally (2-10 samples) or on AWS (2-2000 samples)  
🐳 **Containerized**: All tools packaged in Docker containers  
📊 **Complete Analysis**: FASTQ → QC → Alignment → Quantification → MultiQC  
🧬 **Multi-species**: Pre-configured for human (GRCh38) and mouse (GRCm39)  
⚡ **Auto-scaling**: Nextflow parallelization scales with sample count  
🔄 **Reproducible**: Versioned pipeline with config-driven parameters

## Pipeline Overview

```
FASTQ files → FastQC → TrimGalore → STAR alignment → Salmon quantification → Gene/Transcript counts
                ↓                         ↓                    ↓
              QC reports            BAM files            MultiQC report
```

**Key Tools:**
- **Quality Control**: FastQC, MultiQC
- **Trimming**: TrimGalore (default) or fastp
- **Alignment**: STAR (with or without Salmon)
- **Quantification**: Salmon (default), featureCounts (optional), RSEM
- **Pipeline Version**: nf-core/rnaseq v3.14.0

## Quick Start

### Prerequisites

**Local Execution:**
- Nextflow ≥23.04.0
- Docker
- 8+ GB RAM
- Multi-core CPU recommended

**AWS Execution:**
- AWS CLI configured (`aws configure`)
- AWS Batch queue and compute environment
- S3 bucket for work files
- Appropriate IAM permissions

### Installation

```bash
# Install Nextflow
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# Clone this setup
git clone <your-repo>
cd nf-core-rnaseq-pipeline

# Make scripts executable
chmod +x scripts/*.sh scripts/*.py
```

## Usage

### 1. Prepare Samplesheet

Create a CSV file with your FASTQ file paths:

**Paired-end example:**
```csv
sample,fastq_1,fastq_2,strandedness
SAMPLE_01,/path/to/SAMPLE_01_R1.fastq.gz,/path/to/SAMPLE_01_R2.fastq.gz,reverse
SAMPLE_02,/path/to/SAMPLE_02_R1.fastq.gz,/path/to/SAMPLE_02_R2.fastq.gz,reverse
```

**Single-end example:**
```csv
sample,fastq_1,fastq_2,strandedness
SAMPLE_01,/path/to/SAMPLE_01.fastq.gz,,reverse
SAMPLE_02,/path/to/SAMPLE_02.fastq.gz,,reverse
```

**Strandedness values:**
- `auto` - Pipeline auto-detects (recommended for mixed or unknown)
- `unstranded` - No strand specificity
- `forward` - Forward stranded (e.g., Lexogen QuantSeq FWD)
- `reverse` - Reverse stranded (most common: TruSeq, NEBNext)

**Generate samplesheet automatically:**
```bash
python scripts/generate_samplesheet.py \
    --input_dir /path/to/fastq/ \
    --output samplesheet.csv \
    --strandedness reverse
```

### 2. Run Locally

```bash
# Basic run
./scripts/run_local.sh \
    -i samplesheets/samplesheet.csv \
    -g GRCh38 \
    -o results/

# With resume (if pipeline was interrupted)
./scripts/run_local.sh \
    -i samplesheet.csv \
    -g GRCh38 \
    -o results/ \
    --resume
```

**Or run Nextflow directly:**
```bash
nextflow run nf-core/rnaseq \
    -profile local \
    -c nextflow.config \
    --input samplesheet.csv \
    --genome GRCh38 \
    --outdir results/ \
    --aligner star_salmon \
    --max_cpus 8 \
    --max_memory 32.GB
```

### 3. Run on AWS

**First-time setup:**
```bash
# Configure AWS Batch (one-time)
./scripts/setup_aws_batch.sh

# Update nextflow.config with generated values
# Edit: process.queue, workDir, aws.region
```

**Run pipeline:**
```bash
./scripts/run_aws.sh \
    -i samplesheets/example_human_GRCh38.csv \
    -g GRCh38 \
    -o s3://my-bucket/results
```

**Large-scale run (100-2000 samples):**
```bash
./scripts/run_aws.sh \
    -i samplesheet_large.csv \
    -g GRCh38 \
    -o s3://my-bucket/results \
    -p aws_large_scale
```

## Configuration

### Genome References

Pre-configured genomes (using iGenomes):
- `GRCh38` - Human (NCBI)
- `GRCh38_ensembl` - Human (Ensembl)
- `GRCm39` - Mouse (Ensembl, latest)
- `GRCm38` - Mouse (Ensembl, mm10)

**Custom genome:**
```bash
nextflow run nf-core/rnaseq \
    -profile local \
    --input samplesheet.csv \
    --fasta /path/to/genome.fa \
    --gtf /path/to/genes.gtf \
    --star_index /path/to/star_index/ \
    --outdir results/
```

### Pipeline Parameters

Edit `nextflow.config` or pass via command line:

```bash
# Alignment options
--aligner star_salmon          # star_salmon | star_rsem | hisat2
--pseudo_aligner salmon        # salmon only (no alignment)

# Trimming
--trimmer trimgalore           # trimgalore | fastp
--skip_trimming                # Skip adapter trimming

# QC
--skip_fastqc                  # Skip FastQC
--skip_multiqc                 # Skip MultiQC report

# Performance
--max_cpus 16
--max_memory 128.GB
--max_time 240.h

# Save intermediate files
--save_trimmed
--save_reference
--save_align_intermeds
```

### AWS Configuration

Update these values in `nextflow.config` (aws profile):

```groovy
process.queue = 'your-batch-queue-name'
workDir = 's3://your-bucket/work'
aws.region = 'us-east-1'
```

For large-scale runs, use `aws_large_scale` profile which optimizes:
- Increased parallelization (1000 concurrent jobs)
- Higher resource limits per process
- Optimized retry strategies

## Output Structure

```
results/
├── multiqc/
│   └── star_salmon/
│       └── multiqc_report.html          # Overall QC report
├── star_salmon/
│   ├── *.bam                            # Aligned BAM files
│   ├── salmon.merged.gene_counts.tsv    # Gene-level counts
│   ├── salmon.merged.transcript_counts.tsv  # Transcript counts
│   └── *.bam.bai                        # BAM indices
├── fastqc/                              # FastQC reports
├── trimgalore/                          # Trimmed FASTQ files (if saved)
└── pipeline_info/
    ├── execution_timeline.html
    ├── execution_report.html
    └── execution_trace.txt
```

## Strandedness Detection

The pipeline can auto-detect strandedness using a subset of reads. However, if you know your library prep:

| Library Prep Kit | Strandedness |
|------------------|--------------|
| TruSeq Stranded mRNA | reverse |
| NEBNext Ultra II Directional | reverse |
| Lexogen QuantSeq FWD | forward |
| Lexogen QuantSeq REV | reverse |
| SMARTer Stranded | reverse |
| Standard (non-stranded) | unstranded |

## Performance Guidelines

### Local Execution

| Sample Count | Recommended Resources | Estimated Time |
|--------------|----------------------|----------------|
| 2-5 samples | 8 CPU, 32 GB RAM | 4-8 hours |
| 5-10 samples | 16 CPU, 64 GB RAM | 6-12 hours |
| 10+ samples | Use AWS | - |

### AWS Execution

| Sample Count | Profile | Estimated Cost* | Estimated Time |
|--------------|---------|----------------|----------------|
| 2-20 samples | aws | $5-20 | 2-4 hours |
| 20-100 samples | aws | $20-100 | 3-6 hours |
| 100-500 samples | aws_large_scale | $100-500 | 4-8 hours |
| 500-2000 samples | aws_large_scale | $500-2000 | 6-12 hours |

*Using EC2 Spot instances, costs are approximate

## Troubleshooting

### Common Issues

**1. Pipeline fails during STAR alignment**
- Increase memory: `--max_memory 64.GB` or edit config
- STAR requires ~30GB for human genome

**2. AWS Batch job stuck in RUNNABLE**
- Check compute environment has capacity
- Verify IAM roles and permissions
- Check VPC/subnet configuration

**3. Samplesheet validation error**
- Ensure CSV format is correct
- Check FASTQ file paths exist
- Verify strandedness values are valid

**4. Docker permission denied**
- Run: `sudo usermod -aG docker $USER`
- Log out and back in

### Resume Failed Runs

Nextflow caches completed steps. To resume:

```bash
nextflow run nf-core/rnaseq \
    -profile local \
    -resume \
    --input samplesheet.csv \
    --genome GRCh38 \
    --outdir results/
```

Or use wrapper scripts with `--resume` flag.

## Advanced Usage

### Enable featureCounts

```bash
nextflow run nf-core/rnaseq \
    -profile local \
    --input samplesheet.csv \
    --genome GRCh38 \
    --outdir results/ \
    --aligner star_salmon \
    --extra_star_align_args '--quantMode TranscriptomeSAM GeneCounts'
```

### Process Subset of Samples

Create a samplesheet with only samples of interest:
```bash
head -n 1 full_samplesheet.csv > subset.csv
grep "SAMPLE_0[1-5]" full_samplesheet.csv >> subset.csv
```

### Monitor with Nextflow Tower

```bash
export TOWER_ACCESS_TOKEN=<your-token>
nextflow run nf-core/rnaseq -with-tower ...
```

## File Structure

```
nf-core-rnaseq-pipeline/
├── nextflow.config                  # Main configuration
├── configs/
│   ├── genomes.config              # Reference genome paths
│   └── aws_large_scale.config      # High-throughput AWS config
├── samplesheets/
│   ├── samplesheet_paired_end_template.csv
│   ├── samplesheet_single_end_template.csv
│   ├── example_human_GRCh38.csv
│   └── example_mouse_GRCm39.csv
├── scripts/
│   ├── generate_samplesheet.py     # Auto-generate samplesheet
│   ├── setup_aws_batch.sh          # AWS Batch setup helper
│   ├── run_local.sh                # Local execution wrapper
│   └── run_aws.sh                  # AWS execution wrapper
└── docs/
    └── README.md                    # This file
```

## Resources

- [nf-core/rnaseq documentation](https://nf-co.re/rnaseq)
- [Nextflow documentation](https://www.nextflow.io/docs/latest/)
- [AWS Batch documentation](https://docs.aws.amazon.com/batch/)
- [Salmon documentation](https://salmon.readthedocs.io/)
- [STAR manual](https://github.com/alexdobin/STAR/blob/master/doc/STARmanual.pdf)

## Citation

If you use this pipeline, please cite:

1. **nf-core/rnaseq**: Patel H, Ewels P, Peltzer A, et al. nf-core/rnaseq: RNA sequencing analysis pipeline using STAR, RSEM, HISAT2 or Salmon with gene/isoform counts and extensive quality control. DOI: 10.5281/zenodo.1400710

2. **Nextflow**: Di Tommaso P, et al. (2017) Nextflow enables reproducible computational workflows. Nat Biotechnol. DOI: 10.1038/nbt.3820

3. **Individual tools**: See nf-core/rnaseq documentation for complete citations

## License

This configuration and wrapper scripts are provided as-is under MIT license. The nf-core/rnaseq pipeline and its dependencies maintain their respective licenses.

## Support

For issues:
1. Check nf-core/rnaseq issues: https://github.com/nf-core/rnaseq/issues
2. Nextflow Slack: https://www.nextflow.io/slack-invite.html
3. nf-core Slack: https://nf-co.re/join

---

**Author**: Chris Frank  
**Version**: 1.0.0  
**Last Updated**: December 2024
