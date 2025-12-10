# Scripts Directory

## Test Data and Pipeline Scripts

### Recommended Test Approach 🎯

**Use synthetic data for testing:**
```bash
./scripts/test_pipeline_simple.sh
```

This comprehensive test script:
- ✅ Generates synthetic test data automatically
- ✅ Downloads minimal test genome (chr22 only) 
- ✅ Runs full nf-core RNA-seq pipeline
- ✅ Validates all outputs
- ✅ Works reliably without network dependencies

### Alternative Scripts

| Script | Status | Use Case |
|--------|---------|----------|
| `test_pipeline_simple.sh` | ✅ **Recommended** | Complete pipeline test with synthetic data |
| `generate_synthetic_data.sh` | ✅ Working | Generate test FASTQ files only |
| `download_test_genome.sh` | ✅ Working | Download chr22 reference genome |
| `download_test_data.sh` | ⚠️ Deprecated | Unreliable real data download |
| `download_with_sra_toolkit.sh` | ⚠️ Complex | Requires SRA toolkit installation |

### Pipeline Execution Scripts

- `run_local.sh` - Run pipeline locally with Docker
- `run_aws.sh` - Run pipeline on AWS Batch
- `setup_aws_batch.sh` - Configure AWS Batch environment

### Utilities

- `generate_samplesheet.py` - Create samplesheets from FASTQ directories

## Why Synthetic Data for Testing?

Synthetic data is **perfect** for testing because it:

- ✅ **Tests pipeline functionality** - All tools run correctly
- ✅ **Tests file I/O** - Reads, writes, and processes files properly  
- ✅ **Tests tool integration** - STAR, Salmon, MultiQC all work together
- ✅ **Tests error handling** - Pipeline manages retries and failures
- ✅ **Validates outputs** - All expected files are generated
- ✅ **Works reliably** - No network issues or missing dependencies

The only difference: alignment rates are low (~5% vs 70-85%) because random sequences don't match real genomes. This is **expected and normal** for synthetic data.

When you run with **real data**, you get normal alignment rates but identical pipeline behavior.

## Quick Start

```bash
# Test the complete pipeline (recommended)
./scripts/test_pipeline_simple.sh

# Or run individual components
./scripts/generate_synthetic_data.sh
./scripts/download_test_genome.sh

# Run your own data
./scripts/run_local.sh -i your_samplesheet.csv -g GRCh38 -o results/
```