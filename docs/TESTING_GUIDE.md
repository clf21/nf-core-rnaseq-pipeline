# Testing Guide for nf-core RNA-seq Pipeline

This guide provides multiple options for testing the pipeline, from quickest tests to full realistic runs.

## 🚀 Quick Test Options (Ranked by Speed)

### Option 1: Fastest - Built-in nf-core Test (Recommended First Test)
**Time:** 30-45 minutes | **Download:** ~200 MB | **Realistic:** ✅ Yes

```bash
# Use nf-core's built-in test data
nextflow run nf-core/rnaseq \
    -profile test,docker \
    --outdir test_results_nfcore

# This automatically:
# - Downloads small real RNA-seq data
# - Uses pre-configured test genome
# - Runs full pipeline with 3 samples
# - Validates pipeline installation
```

**What it tests:**
- ✅ Nextflow installation
- ✅ Docker integration
- ✅ Pipeline execution
- ✅ All pipeline steps (QC, trimming, alignment, quantification)
- ✅ Output generation

---

### Option 2: Fast - Real Small Test Data
**Time:** 45-90 minutes | **Download:** ~50 MB | **Realistic:** ✅ Yes

```bash
# Download real subsampled data
./scripts/download_test_data.sh

# Run pipeline
./scripts/run_local.sh \
    -i test_data/samplesheet_real_test.csv \
    -g GRCh38 \
    -o test_results_real/
```

**Dataset details:**
- Human (Homo sapiens) RNA-seq
- 3 samples, ~50K reads each
- 76 bp paired-end
- TruSeq stranded library

---

### Option 3: Very Fast - Synthetic Test Data
**Time:** 10-20 minutes | **Download:** 0 (generated locally) | **Realistic:** ⚠️ No

```bash
# Generate synthetic test data
./scripts/generate_test_data.sh

# Run pipeline
./scripts/run_local.sh \
    -i test_data/samplesheet_test.csv \
    -g GRCh38 \
    -o test_results_synthetic/
```

**⚠️ Warning:** Synthetic random reads won't align well. This tests:
- ✅ File handling and parsing
- ✅ Pipeline execution flow
- ⚠️ NOT realistic alignment/quantification

Use only for debugging, not validation.

---

## 📋 Detailed Testing Instructions

### Before You Start

Verify prerequisites:
```bash
# Check Java
java -version
# Should show: openjdk version "17.x.x"

# Check Nextflow
nextflow -version
# Should show: nextflow version 23.x.x

# Check Docker
docker --version
docker ps
# Should work without errors

# Check Docker resources (important!)
docker info | grep -E "CPUs|Total Memory"
# Should show: 4+ CPUs, 16+ GB memory
```

### Step-by-Step: Option 1 (Built-in Test - Recommended)

```bash
# 1. Navigate to pipeline directory
cd nf-core-rnaseq-pipeline/

# 2. Pull the pipeline (first time only)
nextflow pull nf-core/rnaseq

# 3. Run test
nextflow run nf-core/rnaseq \
    -profile test,docker \
    --outdir test_results_nfcore \
    -resume

# 4. Monitor progress
# You'll see tasks completing: FASTQC, TRIMGALORE, STAR_ALIGN, etc.

# 5. When complete, check results
ls -lh test_results_nfcore/

# 6. View QC report
open test_results_nfcore/multiqc/star_salmon/multiqc_report.html
# Or on Linux: xdg-open test_results_nfcore/multiqc/star_salmon/multiqc_report.html
```

**Expected output structure:**
```
test_results_nfcore/
├── multiqc/
│   └── star_salmon/
│       └── multiqc_report.html     ← Open this!
├── star_salmon/
│   ├── *.bam                       ← Aligned reads
│   ├── salmon.merged.gene_counts.tsv
│   └── salmon.merged.transcript_counts.tsv
├── fastqc/                         ← QC reports
├── trimgalore/                     ← Trimmed reads
└── pipeline_info/
    ├── execution_report.html       ← Resource usage
    └── execution_timeline.html     ← Timing
```

### Step-by-Step: Option 2 (Real Test Data)

```bash
# 1. Download test data
cd nf-core-rnaseq-pipeline/
./scripts/download_test_data.sh

# This creates:
# - test_data/fastq/*.fastq.gz (6 files, ~50 MB total)
# - test_data/samplesheet_real_test.csv

# 2. View samplesheet
cat test_data/samplesheet_real_test.csv

# 3. Run pipeline using wrapper script
./scripts/run_local.sh \
    -i test_data/samplesheet_real_test.csv \
    -g GRCh38 \
    -o test_results_real/

# Or run with nextflow directly for more control
nextflow run nf-core/rnaseq \
    -profile docker \
    --input test_data/samplesheet_real_test.csv \
    --genome GRCh38 \
    --outdir test_results_real/ \
    --aligner star_salmon \
    --max_memory 16.GB \
    --max_cpus 4 \
    -resume

# 4. Check results
ls -lh test_results_real/
open test_results_real/multiqc/star_salmon/multiqc_report.html
```

### Step-by-Step: Option 3 (Synthetic Data)

```bash
# 1. Generate synthetic data
cd nf-core-rnaseq-pipeline/
./scripts/generate_test_data.sh

# This creates:
# - test_data/fastq/*.fastq.gz (6 files, ~500 KB total)
# - test_data/samplesheet_test.csv

# 2. Run pipeline
./scripts/run_local.sh \
    -i test_data/samplesheet_test.csv \
    -g GRCh38 \
    -o test_results_synthetic/

# Note: Alignment rates will be very low (~0-5%) since reads are random
# This is expected for synthetic data!
```

---

## 🎯 What to Check After Test Run

### 1. Pipeline Completed Successfully
```bash
# Check for completion message
# Look for: "Pipeline completed successfully"

# Check exit code
echo $?
# Should be: 0
```

### 2. Key Output Files Present
```bash
# Count matrix (most important for downstream analysis)
ls -lh test_results_*/star_salmon/salmon.merged.gene_counts.tsv

# Should be >0 bytes, with genes as rows, samples as columns
head test_results_*/star_salmon/salmon.merged.gene_counts.tsv
```

### 3. Quality Metrics (Open MultiQC Report)
```bash
open test_results_*/multiqc/star_salmon/multiqc_report.html
```

**Check these metrics:**
- ✅ **FastQC**: Sequence quality, GC content, duplication
- ✅ **TrimGalore**: Adapter removal stats
- ✅ **STAR**: Alignment rate (should be >70% for real data)
- ✅ **Salmon**: Mapping rate, library type detection
- ✅ **Overall**: All samples processed, no failures

### 4. Resource Usage
```bash
open test_results_*/pipeline_info/execution_report.html
```

**Check:**
- Total runtime
- Peak memory usage per process
- CPU efficiency

---

## 🐛 Troubleshooting Test Runs

### Issue: "Cannot allocate memory" or Out of Memory

**Solution:**
```bash
# Reduce max memory in run command
nextflow run nf-core/rnaseq \
    -profile test,docker \
    --outdir test_results \
    --max_memory 8.GB \
    --max_cpus 2

# Or increase Docker resources:
# Docker Desktop → Settings → Resources
# Set Memory to 16+ GB
```

### Issue: Docker pull rate limit exceeded

**Solution:**
```bash
# Login to Docker Hub (free account)
docker login

# Or wait 6 hours for rate limit reset
# Or use alternative registry (if available)
```

### Issue: Pipeline hangs or stalls

**Solution:**
```bash
# Check Docker containers
docker ps

# View logs of running container
docker logs <container-id>

# Kill and restart with -resume
Ctrl+C
nextflow run nf-core/rnaseq -profile test,docker --outdir test_results -resume
```

### Issue: "Process `STAR_ALIGN` terminated with an error exit status"

**Common causes:**
1. Not enough memory (need ~32 GB for human genome)
2. Corrupted genome index download

**Solution:**
```bash
# Use smaller genome for testing
nextflow run nf-core/rnaseq \
    -profile test,docker \
    --genome GRCm39 \
    --outdir test_results  # Mouse genome is smaller

# Or reduce max memory and let it retry
nextflow run nf-core/rnaseq \
    -profile test,docker \
    --outdir test_results \
    --max_memory 16.GB \
    -resume
```

### Issue: Very low alignment rate (0-5%)

**If using synthetic data:** This is expected! Random sequences don't align.

**If using real data:** Check:
```bash
# 1. Verify genome matches species
cat test_data/samplesheet_real_test.csv
# Should use GRCh38 for human, GRCm39 for mouse

# 2. Check strandedness
# Open MultiQC → Salmon section → Check library type detection

# 3. Check read quality
# Open MultiQC → FastQC section → Quality scores
```

---

## 📊 Expected Results by Test Type

### nf-core Test Profile
- **Runtime:** 30-45 min
- **Alignment rate:** 70-85%
- **Genes detected:** ~15,000
- **File sizes:** 
  - Gene counts: ~2 MB
  - BAM files: ~50 MB each
  - MultiQC report: ~5 MB

### Real Test Data
- **Runtime:** 45-90 min
- **Alignment rate:** 70-85%
- **Genes detected:** ~12,000-15,000
- **File sizes:**
  - Gene counts: ~2 MB
  - BAM files: ~100 MB each
  - MultiQC report: ~5 MB

### Synthetic Data
- **Runtime:** 10-20 min
- **Alignment rate:** 0-5% (expected!)
- **Genes detected:** ~100-500
- **File sizes:**
  - Gene counts: ~500 KB
  - BAM files: ~10 MB each
  - MultiQC report: ~2 MB

---

## ✅ Success Criteria

Your test is successful if:

- [ ] Pipeline completes without errors
- [ ] MultiQC report generated
- [ ] Gene count matrix exists with correct format
- [ ] Alignment rate >70% (for real data)
- [ ] All samples present in outputs
- [ ] No process failures in execution report

---

## 🚀 Next Steps After Successful Test

1. **Clean up test data** (optional):
   ```bash
   rm -rf test_results_*/
   rm -rf work/
   rm -rf test_data/
   ```

2. **Run with your real data:**
   ```bash
   # Generate samplesheet for your data
   python scripts/generate_samplesheet.py \
       --input_dir /path/to/your/fastq/ \
       --output my_samples.csv \
       --strandedness reverse
   
   # Run pipeline
   ./scripts/run_local.sh \
       -i my_samples.csv \
       -g GRCh38 \
       -o my_results/
   ```

3. **Optimize for your system:**
   - Adjust `--max_cpus` and `--max_memory` in nextflow.config
   - Based on execution_report.html from test run

4. **Setup AWS for large cohorts:**
   ```bash
   ./scripts/setup_aws_batch.sh
   ```

---

## 💡 Tips for Testing

1. **Start with nf-core test profile** - Most reliable first test
2. **Use `-resume`** - If test fails, fixes issue and rerun with -resume to skip completed steps
3. **Check Docker resources** - Many failures due to insufficient RAM
4. **Monitor with `docker stats`** - Watch resource usage during run
5. **Save test results** - Use as reference for expected outputs

---

## 📞 Need Help?

If tests fail:
1. Check error messages in terminal
2. Review `work/<hash>/.command.log` for failed process
3. Check Docker logs: `docker logs <container-id>`
4. Ensure sufficient resources (16+ GB RAM recommended)
5. Try nf-core test profile first - if that works, issue is with your data/config

Still stuck? See main [README.md](README.md) troubleshooting section.
