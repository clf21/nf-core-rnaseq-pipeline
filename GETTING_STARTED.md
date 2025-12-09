# Getting Started Checklist

Complete this checklist to get your nf-core RNA-seq pipeline operational.

## Prerequisites Checklist

### Software (Local Execution)
- [ ] Nextflow ≥23.04.0 installed
  ```bash
  curl -s https://get.nextflow.io | bash
  sudo mv nextflow /usr/local/bin/
  nextflow -version
  ```
- [ ] Docker installed and running
  ```bash
  docker --version
  docker ps
  ```
- [ ] Python 3.7+ (for samplesheet generation)
  ```bash
  python --version
  ```

### AWS Setup (Cloud Execution)
- [ ] AWS CLI installed and configured
  ```bash
  aws --version
  aws configure
  aws sts get-caller-identity
  ```
- [ ] IAM permissions for Batch, EC2, S3, IAM
- [ ] Default region set (e.g., us-east-1)

## Initial Setup

### 1. Clone/Download Pipeline
- [ ] Download the nf-core-rnaseq-pipeline directory
- [ ] Verify all files present (see FILE_STRUCTURE.md)
- [ ] Make scripts executable
  ```bash
  chmod +x scripts/*.sh scripts/*.py
  ```

### 2. Test Nextflow
- [ ] Run Nextflow test
  ```bash
  nextflow info
  ```
- [ ] Pull nf-core/rnaseq pipeline
  ```bash
  nextflow pull nf-core/rnaseq
  ```

### 3. Configuration Review
- [ ] Review `nextflow.config`
- [ ] Check genome configurations in `configs/genomes.config`
- [ ] Verify Docker settings (local profile)

## Local Execution Setup

### Prerequisites
- [ ] Have FASTQ files ready
- [ ] Know your genome (GRCh38 or GRCm39)
- [ ] Know your library strandedness
- [ ] Have ~100GB free disk space minimum

### Steps
1. [ ] Create samplesheet
   ```bash
   # Option A: Manual
   # Edit samplesheets/samplesheet_paired_end_template.csv
   
   # Option B: Auto-generate
   python scripts/generate_samplesheet.py \
       --input_dir /path/to/fastq/ \
       --output my_samplesheet.csv \
       --strandedness reverse
   ```

2. [ ] Verify samplesheet format
   ```bash
   head my_samplesheet.csv
   # Check: sample,fastq_1,fastq_2,strandedness
   ```

3. [ ] Run test with 2 samples
   ```bash
   ./scripts/run_local.sh \
       -i my_samplesheet.csv \
       -g GRCh38 \
       -o test_results/
   ```

4. [ ] Review results
   ```bash
   open test_results/multiqc/star_salmon/multiqc_report.html
   ```

## AWS Execution Setup

### One-Time Infrastructure Setup
- [ ] Run AWS Batch setup script
  ```bash
  ./scripts/setup_aws_batch.sh
  ```
- [ ] Note the generated values:
  - [ ] Compute Environment name: _______________
  - [ ] Job Queue name: _______________
  - [ ] S3 Bucket: _______________

- [ ] Update `nextflow.config` with generated values
  ```groovy
  // In aws profile
  process.queue = 'your-queue-name'
  workDir = 's3://your-bucket/work'
  aws.region = 'your-region'
  ```

### Data Preparation
- [ ] Upload FASTQ files to S3 (or confirm local paths)
  ```bash
  aws s3 sync /path/to/fastq/ s3://your-bucket/fastq/
  ```

- [ ] Create samplesheet with S3 paths
  ```csv
  sample,fastq_1,fastq_2,strandedness
  S1,s3://bucket/fastq/S1_R1.fq.gz,s3://bucket/fastq/S1_R2.fq.gz,reverse
  ```

### First AWS Run
- [ ] Run small test (2-5 samples)
  ```bash
  ./scripts/run_aws.sh \
      -i samplesheet.csv \
      -g GRCh38 \
      -o s3://your-bucket/test_results
  ```

- [ ] Monitor in AWS Console
  - [ ] AWS Batch: https://console.aws.amazon.com/batch/
  - [ ] CloudWatch Logs: Check for errors

- [ ] Download results
  ```bash
  aws s3 sync s3://your-bucket/test_results/ ./local_results/
  ```

## Validation Checklist

### Verify Pipeline Outputs
- [ ] MultiQC report generated
  - Path: `results/multiqc/star_salmon/multiqc_report.html`
  
- [ ] Gene count matrix present
  - Path: `results/star_salmon/salmon.merged.gene_counts.tsv`
  - Check: Should have samples as columns, genes as rows
  
- [ ] Transcript counts present
  - Path: `results/star_salmon/salmon.merged.transcript_counts.tsv`
  
- [ ] BAM files generated (if not skipped)
  - Path: `results/star_salmon/*.bam`
  
- [ ] Execution reports present
  - Path: `results/pipeline_info/`
  - Files: execution_timeline.html, execution_report.html

### Quality Checks
- [ ] Alignment rate > 70%
  - Check in MultiQC report → "STAR" section
  
- [ ] Genes detected ~10,000-15,000 (human)
  - Check gene count matrix row count
  
- [ ] Strandedness matches expectation
  - Check in MultiQC report → "Salmon" section
  
- [ ] No systematic batch effects
  - Check in MultiQC report → Sample correlations

## Production Run Checklist

### Before Large-Scale Run
- [ ] Successful test run completed
- [ ] Strandedness confirmed from test
- [ ] Resource allocations reviewed for sample count
- [ ] Cost estimate calculated (AWS)
- [ ] Backup strategy defined for results
- [ ] Monitoring setup (Tower or CloudWatch)

### For AWS Large-Scale (>100 samples)
- [ ] Use `aws_large_scale` profile
  ```bash
  ./scripts/run_aws.sh \
      -i large_samplesheet.csv \
      -g GRCh38 \
      -o s3://bucket/results \
      -p aws_large_scale
  ```
- [ ] Monitor job queue size
- [ ] Check for stuck jobs
- [ ] Verify S3 costs acceptable

### After Completion
- [ ] Download key results to local
- [ ] Verify output completeness
- [ ] Clean up work directory
  ```bash
  # AWS: Delete S3 work directory after verification
  aws s3 rm s3://bucket/work/ --recursive
  ```
- [ ] Archive results if needed
- [ ] Document parameters used

## Common First-Run Issues

### Issue: Docker permission denied
**Solution:**
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Issue: Out of memory (local)
**Solution:**
```bash
# Increase max memory in nextflow.config
params.max_memory = 64.GB
```

### Issue: AWS jobs stuck in RUNNABLE
**Solution:**
- Check compute environment status in AWS Console
- Verify IAM roles attached correctly
- Check VPC/subnet configuration
- Ensure service limits not exceeded

### Issue: Genome not found
**Solution:**
```bash
# Use direct paths instead of genome name
nextflow run nf-core/rnaseq \
    --fasta /path/to/genome.fa \
    --gtf /path/to/genes.gtf \
    ...
```

### Issue: Samplesheet validation failed
**Solution:**
- Ensure CSV format (not TSV)
- Check file paths exist
- Verify strandedness values are valid
- No spaces in sample names

## Next Steps After Successful Run

1. [ ] Review comprehensive documentation
   - [ ] Read README.md for full details
   - [ ] Review AWS_BEST_PRACTICES.md for optimization

2. [ ] Perform downstream analysis
   - [ ] Follow docs/downstream_analysis_example.R
   - [ ] Import counts into DESeq2/edgeR
   - [ ] Generate visualizations

3. [ ] Optimize for your use case
   - [ ] Adjust resource allocations based on timing
   - [ ] Fine-tune cost vs performance (AWS)
   - [ ] Set up automated workflows if needed

4. [ ] Share with team
   - [ ] Document your specific configuration
   - [ ] Create standard operating procedure
   - [ ] Set up version control for configs

## Support Resources

If stuck, consult:
1. [ ] QUICKSTART.md - Fast troubleshooting
2. [ ] README.md - Comprehensive guide
3. [ ] nf-core/rnaseq docs - https://nf-co.re/rnaseq
4. [ ] nf-core Slack - https://nf-co.re/join
5. [ ] GitHub issues - https://github.com/nf-core/rnaseq/issues

## Ready to Scale?

Once comfortable with the pipeline:
- [ ] Process full dataset
- [ ] Integrate with downstream workflows
- [ ] Set up automated QC checks
- [ ] Document project-specific parameters

---

**Estimated Time to Complete Setup:**
- Local: 30 minutes
- AWS: 1-2 hours (including infrastructure setup)

**First successful run:** ~4 hours (local, 2-5 samples) or ~2-3 hours (AWS)

Good luck with your RNA-seq analysis!
