# Quick Start Guide

Get up and running with nf-core RNA-seq pipeline in 5 minutes.

## Step 1: Install Dependencies

```bash
# Install Nextflow
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/

# Verify installation
nextflow -version  # Should show ≥23.04.0

# Ensure Docker is running
docker --version
docker ps  # Should not error
```

## Step 2: Test Local Execution

```bash
cd nf-core-rnaseq-pipeline

# Pull the pipeline (first time only)
nextflow pull nf-core/rnaseq

# Run test dataset (human, 2 samples)
nextflow run nf-core/rnaseq \
    -profile test,docker \
    --outdir test_results

# This downloads ~1GB test data and runs in ~30 minutes
```

## Step 3: Create Your Samplesheet

### Option A: Manual Creation

Create `my_samplesheet.csv`:
```csv
sample,fastq_1,fastq_2,strandedness
CTRL_1,/data/CTRL_1_R1.fastq.gz,/data/CTRL_1_R2.fastq.gz,reverse
CTRL_2,/data/CTRL_2_R1.fastq.gz,/data/CTRL_2_R2.fastq.gz,reverse
TREAT_1,/data/TREAT_1_R1.fastq.gz,/data/TREAT_1_R2.fastq.gz,reverse
TREAT_2,/data/TREAT_2_R1.fastq.gz,/data/TREAT_2_R2.fastq.gz,reverse
```

### Option B: Auto-Generate

```bash
python scripts/generate_samplesheet.py \
    --input_dir /path/to/fastq_files/ \
    --output my_samplesheet.csv \
    --strandedness reverse
```

## Step 4: Run Your Analysis

### Local (< 10 samples)

```bash
# Quick run
./scripts/run_local.sh \
    -i my_samplesheet.csv \
    -g GRCh38 \
    -o results_human

# Mouse samples
./scripts/run_local.sh \
    -i my_samplesheet.csv \
    -g GRCm39 \
    -o results_mouse
```

### AWS (10-2000 samples)

```bash
# One-time AWS setup
./scripts/setup_aws_batch.sh

# Edit nextflow.config with generated values

# Run on AWS
./scripts/run_aws.sh \
    -i my_samplesheet.csv \
    -g GRCh38 \
    -o s3://my-bucket/results
```

## Step 5: View Results

```bash
# Open MultiQC report
open results_human/multiqc/star_salmon/multiqc_report.html

# Gene counts (for DESeq2, edgeR, etc.)
head results_human/star_salmon/salmon.merged.gene_counts.tsv

# Transcript counts
head results_human/star_salmon/salmon.merged.transcript_counts.tsv
```

## Next Steps

- **Differential Expression**: Import counts into DESeq2 or edgeR
- **Visualization**: Use Salmon outputs with tximport
- **GSEA**: Use gene counts for pathway analysis
- **Scale Up**: Process larger cohorts on AWS

## Common Commands

```bash
# Check pipeline status
nextflow log

# Resume failed run
nextflow run nf-core/rnaseq -resume [other options]

# Clean work directory (saves space)
nextflow clean -f

# View available genomes
less configs/genomes.config
```

## Troubleshooting First Run

**Problem**: "Docker permission denied"
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

**Problem**: "Cannot find genome GRCh38"
```bash
# Check genome config
grep -A 5 "GRCh38" nextflow.config

# Or use direct paths
nextflow run nf-core/rnaseq \
    --fasta /path/to/genome.fa \
    --gtf /path/to/genes.gtf
```

**Problem**: Out of memory
```bash
# Increase max memory
--max_memory 64.GB

# Or edit nextflow.config
params.max_memory = 64.GB
```

## Resource Requirements

**Minimum (local):**
- 4 CPU cores
- 16 GB RAM
- 100 GB disk space

**Recommended (local):**
- 8+ CPU cores
- 32+ GB RAM
- 500 GB disk space

**AWS:**
- Scales automatically based on sample count
- Spot instances reduce costs by ~70%

## Example Timing

| Samples | Reads/Sample | Local Time | AWS Time | 
|---------|-------------|------------|----------|
| 2 | 20M | 4 hours | 2 hours |
| 6 | 30M | 12 hours | 3 hours |
| 50 | 25M | N/A | 6 hours |
| 500 | 30M | N/A | 10 hours |

---

**Need Help?**
- Full documentation: See [README.md](README.md)
- nf-core Slack: https://nf-co.re/join
- Issues: https://github.com/nf-core/rnaseq/issues
