# nf-core RNA-seq Pipeline - Complete Setup Package

**Version:** 1.0.0  
**Pipeline:** nf-core/rnaseq v3.14.0  
**Created:** December 2024  
**Author:** Chris Frank

---

## 📋 Quick Navigation

### Start Here
1. **[GETTING_STARTED.md](GETTING_STARTED.md)** - Complete checklist to get operational
2. **[QUICKSTART.md](docs/QUICKSTART.md)** - 5-minute fast start
3. **[README.md](README.md)** - Full documentation

### Core Configuration
- **[nextflow.config](nextflow.config)** - Main configuration with local/AWS profiles
- **[configs/genomes.config](configs/genomes.config)** - GRCh38 & GRCm39 references
- **[configs/aws_large_scale.config](configs/aws_large_scale.config)** - High-throughput AWS

### Execution Scripts
- **[scripts/run_local.sh](scripts/run_local.sh)** - Local execution (2-10 samples)
- **[scripts/run_aws.sh](scripts/run_aws.sh)** - AWS execution (2-2000 samples)
- **[scripts/setup_aws_batch.sh](scripts/setup_aws_batch.sh)** - One-time AWS setup
- **[scripts/generate_samplesheet.py](scripts/generate_samplesheet.py)** - Auto-generate samplesheet

### Documentation
- **[PIPELINE_SUMMARY.md](PIPELINE_SUMMARY.md)** - Quick reference
- **[FILE_STRUCTURE.md](FILE_STRUCTURE.md)** - Directory organization
- **[docs/AWS_BEST_PRACTICES.md](docs/AWS_BEST_PRACTICES.md)** - Cost & performance
- **[docs/downstream_analysis_example.R](docs/downstream_analysis_example.R)** - DESeq2 workflow

---

## 🚀 Quick Start Commands

### Test Installation
```bash
# Verify Nextflow
nextflow -version

# Pull pipeline
nextflow pull nf-core/rnaseq

# Test with public data
nextflow run nf-core/rnaseq -profile test,docker --outdir test_results
```

### Generate Samplesheet
```bash
python scripts/generate_samplesheet.py \
    --input_dir /path/to/fastq/ \
    --output my_samples.csv \
    --strandedness reverse
```

### Run Locally
```bash
./scripts/run_local.sh \
    -i my_samples.csv \
    -g GRCh38 \
    -o results/
```

### Run on AWS
```bash
# One-time setup
./scripts/setup_aws_batch.sh

# Run pipeline
./scripts/run_aws.sh \
    -i my_samples.csv \
    -g GRCh38 \
    -o s3://my-bucket/results
```

---

## 📦 What's Included

### Configuration Files (3)
- ✅ **nextflow.config** - Main config with 3 profiles
- ✅ **genomes.config** - 4 pre-configured genomes
- ✅ **aws_large_scale.config** - Optimized for 100-2000 samples

### Sample Templates (4)
- ✅ Paired-end template
- ✅ Single-end template  
- ✅ Human (GRCh38) example
- ✅ Mouse (GRCm39) example

### Scripts (4)
- ✅ **generate_samplesheet.py** - Auto-generate from FASTQ directory
- ✅ **setup_aws_batch.sh** - Interactive AWS infrastructure setup
- ✅ **run_local.sh** - Simplified local execution
- ✅ **run_aws.sh** - Simplified AWS execution

### Documentation (9)
- ✅ **README.md** - Comprehensive user guide (2500+ lines)
- ✅ **GETTING_STARTED.md** - Step-by-step checklist
- ✅ **QUICKSTART.md** - 5-minute guide
- ✅ **PIPELINE_SUMMARY.md** - Quick reference
- ✅ **FILE_STRUCTURE.md** - Directory organization
- ✅ **AWS_BEST_PRACTICES.md** - Production deployment guide
- ✅ **downstream_analysis_example.R** - Complete DESeq2 workflow
- ✅ This INDEX.md

**Total:** ~3,500 lines of configuration and documentation

---

## 🎯 Usage Scenarios

### Scenario 1: Local Testing (2-5 samples)
```bash
# 1. Generate samplesheet
python scripts/generate_samplesheet.py \
    --input_dir ./fastq --output test.csv

# 2. Run
./scripts/run_local.sh -i test.csv -g GRCh38 -o results/

# 3. View results
open results/multiqc/star_salmon/multiqc_report.html
```

**Time:** ~4 hours  
**Resources:** 8 cores, 32 GB RAM

---

### Scenario 2: AWS Small Cohort (10-50 samples)
```bash
# 1. Setup AWS (one-time)
./scripts/setup_aws_batch.sh

# 2. Upload data to S3
aws s3 sync ./fastq s3://my-bucket/fastq/

# 3. Create samplesheet with S3 paths
python scripts/generate_samplesheet.py \
    --input_dir ./fastq \
    --output samples.csv \
    --s3_bucket s3://my-bucket/fastq \
    --local_prefix ./fastq

# 4. Run
./scripts/run_aws.sh \
    -i samples.csv \
    -g GRCh38 \
    -o s3://my-bucket/results

# 5. Download results
aws s3 sync s3://my-bucket/results ./local_results/
```

**Time:** ~3-5 hours  
**Cost:** ~$20-40 (Spot instances)

---

### Scenario 3: AWS Large Cohort (100-500 samples)
```bash
# Use large-scale profile
./scripts/run_aws.sh \
    -i large_cohort.csv \
    -g GRCh38 \
    -o s3://my-bucket/results \
    -p aws_large_scale
```

**Time:** ~6-10 hours  
**Cost:** ~$100-300 (Spot instances)

---

## 📊 Pipeline Workflow

```
FASTQ Files
    ↓
FastQC (Quality Control)
    ↓
TrimGalore (Adapter Trimming)
    ↓
STAR (Genome Alignment)
    ↓
Salmon (Transcript Quantification)
    ↓
MultiQC (Aggregate Report)
    ↓
Outputs:
├── Gene counts (salmon.merged.gene_counts.tsv)
├── Transcript counts (salmon.merged.transcript_counts.tsv)
├── BAM files (*.bam)
└── QC reports (multiqc_report.html)
```

---

## 🔧 Key Configuration Options

### Genome Selection
- `GRCh38` - Human (NCBI)
- `GRCh38_ensembl` - Human (Ensembl)
- `GRCm39` - Mouse (latest)
- `GRCm38` - Mouse (mm10)
- Custom: Provide FASTA + GTF

### Strandedness
- `auto` - Pipeline detects (recommended)
- `unstranded` - No strand info
- `forward` - Forward stranded
- `reverse` - Reverse stranded (most common)

### Aligner Options
- `star_salmon` - STAR + Salmon (default, recommended)
- `star_rsem` - STAR + RSEM
- `hisat2` - HISAT2 aligner
- `salmon` - Pseudo-alignment only

---

## 📈 Expected Outputs

### Primary Files
```
results/
├── multiqc/star_salmon/multiqc_report.html    # QC summary
├── star_salmon/
│   ├── salmon.merged.gene_counts.tsv          # For DESeq2/edgeR
│   ├── salmon.merged.transcript_counts.tsv    # For sleuth
│   └── *.bam                                  # Aligned reads
└── pipeline_info/
    ├── execution_report.html                  # Resource usage
    └── execution_timeline.html                # Timing
```

### File Sizes (approximate)
- Gene counts: ~5-10 MB (depends on genome)
- Transcript counts: ~20-50 MB
- BAM files: ~2-5 GB per sample
- MultiQC report: ~5-10 MB

---

## 💰 Cost Estimates (AWS Spot Instances)

| Samples | Human Genome | Mouse Genome | Time | Storage |
|---------|--------------|--------------|------|---------|
| 10 | $8-12 | $6-10 | 3h | 50 GB |
| 50 | $40-60 | $30-45 | 5h | 250 GB |
| 100 | $80-120 | $60-90 | 7h | 500 GB |
| 500 | $300-450 | $225-340 | 10h | 2.5 TB |

**Cost factors:**
- Read depth (20M vs 50M reads per sample)
- Genome size (human > mouse)
- Spot vs On-Demand (Spot ~70% cheaper)

---

## 🛠 Troubleshooting Quick Reference

### Common Issues

| Issue | Solution |
|-------|----------|
| Docker permission denied | `sudo usermod -aG docker $USER` + logout |
| Out of memory | Increase `--max_memory 64.GB` |
| AWS jobs stuck | Check compute environment status |
| Genome not found | Use `--fasta` and `--gtf` directly |
| Samplesheet error | Verify CSV format, check file paths |

### Check Pipeline Status
```bash
# View running processes
nextflow log

# Resume failed run
nextflow run nf-core/rnaseq -resume ...

# Clean up work files
nextflow clean -f
```

---

## 📚 Learning Path

### Beginner (Days 1-2)
1. Read GETTING_STARTED.md
2. Complete checklist
3. Run test with 2 samples locally
4. Review MultiQC report

### Intermediate (Week 1)
1. Process your full dataset
2. Understand outputs in README.md
3. Run downstream analysis (R script)
4. Optimize resource usage

### Advanced (Month 1)
1. Setup AWS infrastructure
2. Process large cohorts (100+ samples)
3. Implement AWS best practices
4. Integrate with your analysis pipeline

---

## 🔗 Important Links

### Official Documentation
- **nf-core/rnaseq**: https://nf-co.re/rnaseq
- **Nextflow**: https://www.nextflow.io/docs/
- **AWS Batch**: https://docs.aws.amazon.com/batch/

### Community Support
- **nf-core Slack**: https://nf-co.re/join
- **Nextflow Gitter**: https://gitter.im/nextflow-io/nextflow
- **GitHub Issues**: https://github.com/nf-core/rnaseq/issues

### Tools Documentation
- **STAR**: https://github.com/alexdobin/STAR
- **Salmon**: https://salmon.readthedocs.io/
- **DESeq2**: https://bioconductor.org/packages/DESeq2/
- **MultiQC**: https://multiqc.info/

---

## ✅ Pre-flight Checklist

Before your first production run:

- [ ] Nextflow installed and tested
- [ ] Docker working (local) OR AWS Batch configured (cloud)
- [ ] Test run completed successfully
- [ ] Samplesheet validated
- [ ] Genome reference confirmed
- [ ] Strandedness known
- [ ] Output directory prepared
- [ ] Resource requirements estimated
- [ ] Backup strategy defined
- [ ] Team trained on pipeline

---

## 🎓 Citation

If you use this pipeline setup, please cite:

**nf-core/rnaseq:**
Patel H, Ewels P, Peltzer A, et al. nf-core/rnaseq: RNA sequencing analysis pipeline. 
Zenodo. doi:10.5281/zenodo.1400710

**Nextflow:**
Di Tommaso P, et al. (2017) Nextflow enables reproducible computational workflows. 
Nat Biotechnol. 35(4):316-319. doi:10.1038/nbt.3820

---

## 📞 Support

If you encounter issues:

1. **Check documentation** in order:
   - GETTING_STARTED.md (checklist format)
   - QUICKSTART.md (troubleshooting)
   - README.md (comprehensive)
   - AWS_BEST_PRACTICES.md (AWS-specific)

2. **Search existing issues**:
   - https://github.com/nf-core/rnaseq/issues

3. **Ask the community**:
   - nf-core Slack (fastest response)
   - Nextflow Gitter

4. **File a bug report**:
   - Include: pipeline version, config, error message, logs

---

## 📝 Changelog

### v1.0.0 (December 2024)
- Initial release
- Support for nf-core/rnaseq v3.14.0
- Local and AWS Batch execution
- Human (GRCh38) and mouse (GRCm39) genomes
- Complete documentation suite
- Downstream analysis examples

---

## 🚀 You're Ready!

Everything you need is included in this package. Start with **GETTING_STARTED.md** and work through the checklist.

**Estimated time to first results:**
- Setup: 30 min (local) or 1-2 hours (AWS)
- Test run: 2-4 hours
- **Total: 3-6 hours to operational pipeline**

Good luck with your RNA-seq analysis!

---

**Questions?** Start with GETTING_STARTED.md → README.md → Community Slack
