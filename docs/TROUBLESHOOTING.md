# Common Errors and Solutions

## Error: Genome fasta file not specified

### Full Error Message:
```
Genome fasta file not specified with e.g. '--fasta genome.fa' or via a detectable config file. 
You must supply a genome FASTA file or use --skip_alignment and provide your own transcript 
fasta using --transcript_fasta for use in quantification.
```

### Cause:
The pipeline can't find the genome reference files for the specified genome.

### Solution 1: Use nf-core's Built-in iGenomes (Recommended)

Run directly with nf-core's profiles instead of custom wrapper:

```bash
nextflow run nf-core/rnaseq \
    -profile docker \
    --input test_data/samplesheet_real_test.csv \
    --genome GRCh38 \
    --outdir test_results/ \
    --max_memory 16.GB \
    --max_cpus 4
```

**Why this works:** nf-core/rnaseq has built-in support for common genomes that automatically downloads references from AWS iGenomes.

### Solution 2: Updated Wrapper Script

I've updated the `run_local.sh` script to work correctly. Try again:

```bash
./scripts/run_local.sh \
    -i test_data/samplesheet_real_test.csv \
    -g GRCh38 \
    -o test_results/
```

### Solution 3: Provide Custom Genome Files

If you have your own genome files:

```bash
nextflow run nf-core/rnaseq \
    -profile docker \
    --input samplesheet.csv \
    --fasta /path/to/genome.fa \
    --gtf /path/to/genes.gtf \
    --outdir results/
```

The pipeline will build indices automatically from FASTA and GTF.

---

## Warning: Graphviz is required to render the execution DAG

### Full Warning Message:
```
WARN: Graphviz is required to render the execution DAG in the given format -- 
See http://www.graphviz.org for more info.
```

### Cause:
Graphviz is not installed, so Nextflow can't generate the visual pipeline DAG (directed acyclic graph).

### Impact:
**This is just a warning - it does NOT affect pipeline execution.** The pipeline will run successfully without Graphviz. You just won't get the visual DAG diagram (pipeline_dag.svg).

### Solution (Optional):

If you want the visual DAG, install Graphviz:

**macOS:**
```bash
brew install graphviz
```

**Ubuntu/Debian:**
```bash
sudo apt-get install graphviz
```

**Red Hat/CentOS:**
```bash
sudo yum install graphviz
```

Then re-run with `-resume` to keep completed work.

### To Disable DAG Generation:

If you don't need the DAG and want to suppress the warning, edit `nextflow.config`:

```groovy
dag {
    enabled = false  // Change from true to false
    file = "${params.outdir}/pipeline_info/pipeline_dag.svg"
}
```

---

## Error: Cannot allocate memory

### Full Error Message:
```
Process `STAR_ALIGN` terminated with an error exit status (137)
```

Exit status 137 = killed by out-of-memory (OOM) killer.

### Solution 1: Increase Docker Memory

**Docker Desktop:**
1. Settings → Resources
2. Increase Memory to 32+ GB (minimum 16 GB for human genome)
3. Apply & Restart

### Solution 2: Reduce Pipeline Memory Limits

```bash
nextflow run nf-core/rnaseq \
    -profile docker \
    --input samplesheet.csv \
    --genome GRCh38 \
    --outdir results/ \
    --max_memory 16.GB \
    --max_cpus 4
```

### Solution 3: Use Smaller Genome for Testing

Mouse genome requires less memory:

```bash
nextflow run nf-core/rnaseq \
    -profile docker \
    --input samplesheet.csv \
    --genome GRCm39 \
    --outdir results/
```

---

## Error: Docker permission denied

### Full Error Message:
```
docker: Got permission denied while trying to connect to the Docker daemon socket
```

### Solution (Linux):

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes (logout/login or run)
newgrp docker

# Test
docker ps
```

### Solution (macOS):

Ensure Docker Desktop is running:
```bash
open /Applications/Docker.app
```

---

## Error: Cannot connect to Docker daemon

### Full Error Message:
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

### Solution:

**Start Docker:**

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker  # Start on boot
```

**macOS/Windows:**
- Launch Docker Desktop application
- Wait for whale icon in menu bar/system tray

---

## Error: Rate limit exceeded (Docker Hub)

### Full Error Message:
```
toomanyrequests: You have reached your pull rate limit
```

### Solution:

**Option 1: Login to Docker Hub**
```bash
docker login
# Enter your Docker Hub username and password
# Free account gives higher rate limits
```

**Option 2: Wait and Retry**
Rate limits reset after 6 hours. Try again later.

**Option 3: Use `-resume`**
If you hit rate limit mid-pipeline:
```bash
# Wait 6 hours, then resume
nextflow run nf-core/rnaseq [same options] -resume
```

---

## Error: Pipeline hangs or stalls

### Symptoms:
- No progress for >30 minutes
- No new log messages
- Processes stuck in "running" state

### Diagnosis:

```bash
# Check running containers
docker ps

# Check container logs
docker logs <container-id>

# Check system resources
docker stats
```

### Solution 1: Kill and Resume

```bash
# Kill pipeline (Ctrl+C or)
kill <nextflow-pid>

# Resume (keeps completed work)
nextflow run nf-core/rnaseq [same options] -resume
```

### Solution 2: Increase Timeout

If specific process times out, edit `nextflow.config`:

```groovy
process {
    time = { check_max(24.h * task.attempt, 'time') }
}
```

---

## Error: Samplesheet validation failed

### Common Causes:

1. **Wrong delimiter**: Use commas (`,`) not tabs
2. **Missing columns**: Must have: sample, fastq_1, fastq_2, strandedness
3. **File paths don't exist**: Check all FASTQ paths are correct
4. **Invalid strandedness**: Use: auto, unstranded, forward, or reverse
5. **Duplicate sample names**: Each sample must be unique
6. **Spaces in sample names**: Remove spaces from sample IDs

### Solution:

Verify samplesheet format:

```bash
# Check format
head samplesheet.csv

# Should look like:
sample,fastq_1,fastq_2,strandedness
SAMPLE1,/path/R1.fq.gz,/path/R2.fq.gz,reverse
```

Use the generator script:
```bash
python scripts/generate_samplesheet.py \
    --input_dir /path/to/fastq/ \
    --output samplesheet.csv
```

---

## Error: Java version too old

### Full Error Message:
```
Nextflow requires Java 11 or later
```

### Solution:

Install Java 17:

```bash
# Using SDKMAN (recommended)
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 17.0.9-tem

# Verify
java -version
```

---

## Error: Work directory too large

### Symptoms:
- Disk space running out
- Error: "No space left on device"

### Solution:

**Clean up after successful run:**
```bash
# Remove work directory
rm -rf work/

# Remove .nextflow cache
rm -rf .nextflow/
rm .nextflow.log*
```

**Or use `-resume` to avoid re-running:**
```bash
# Fix issue and resume (keeps work directory)
nextflow run nf-core/rnaseq [options] -resume

# After success, clean up
rm -rf work/
```

**Configure work directory location:**
```bash
# Use external disk with more space
nextflow run nf-core/rnaseq \
    [options] \
    -work-dir /path/to/large/disk/work
```

---

## Error: Very low alignment rate (0-5%)

### Possible Causes:

1. **Wrong genome**: Human samples with mouse genome (or vice versa)
2. **Wrong strandedness**: Library prep doesn't match specified strandedness
3. **Poor quality data**: Check FastQC reports
4. **Contamination**: Non-target organism sequences
5. **Synthetic data**: Random reads don't align (expected for test data)

### Diagnosis:

Check MultiQC report:
- FastQC: Quality scores, GC content
- STAR: Alignment statistics
- Salmon: Library type detection

### Solution:

1. **Verify genome matches samples:**
   ```bash
   # Use correct genome
   --genome GRCh38  # For human
   --genome GRCm39  # For mouse
   ```

2. **Check strandedness:**
   Look in MultiQC → Salmon section for detected library type

3. **Try auto-detection:**
   ```bash
   --strandedness auto
   ```

---

## Getting More Help

### Enable Debug Mode:

```bash
nextflow run nf-core/rnaseq \
    [options] \
    -with-trace \
    -with-report \
    -with-timeline \
    -with-dag
```

### Check Detailed Logs:

```bash
# Find failed process
ls -lt work/

# View error log
cat work/<hash>/.command.log
cat work/<hash>/.command.err

# View full command
cat work/<hash>/.command.sh
```

### Report Issues:

1. Check nf-core issues: https://github.com/nf-core/rnaseq/issues
2. Include:
   - Nextflow version
   - Pipeline version
   - Error message
   - Command used
   - Relevant log files

### Community Support:

- nf-core Slack: https://nf-co.re/join
- Nextflow Gitter: https://gitter.im/nextflow-io/nextflow
