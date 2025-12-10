#!/bin/bash
# Download real small test RNA-seq data from public repositories
# Uses subsampled data from nf-core test datasets

set -euo pipefail

echo "============================================================================="
echo "Downloading Real Test Data for nf-core RNA-seq Pipeline"
echo "============================================================================="
echo ""
echo "This will download small (~50 MB) real RNA-seq FASTQ files."
echo ""

# Create directory
mkdir -p test_data/fastq
cd test_data/fastq

echo "Downloading test FASTQ files from nf-core..."
echo ""

# Download small test files from nf-core test data
# These are real Homo sapiens RNA-seq reads, subsampled to ~50K reads each

BASE_URL="https://github.com/nf-core/test-datasets/raw/rnaseq/testdata"

files=(
    "SRR6357070_1.fastq.gz"
    "SRR6357070_2.fastq.gz"
    "SRR6357071_1.fastq.gz"
    "SRR6357071_2.fastq.gz"
    "SRR6357072_1.fastq.gz"
    "SRR6357072_2.fastq.gz"
)

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Downloading ${file}..."
        curl -L -o "${file}" "${BASE_URL}/${file}"
    else
        echo "✓ ${file} already exists"
    fi
done

cd ../..

# Create samplesheet
echo ""
echo "Creating samplesheet..."

cat > test_data/samplesheet_real_test.csv << 'EOF'
sample,fastq_1,fastq_2,strandedness
SRR6357070,test_data/fastq/SRR6357070_1.fastq.gz,test_data/fastq/SRR6357070_2.fastq.gz,reverse
SRR6357071,test_data/fastq/SRR6357071_1.fastq.gz,test_data/fastq/SRR6357071_2.fastq.gz,reverse
SRR6357072,test_data/fastq/SRR6357072_1.fastq.gz,test_data/fastq/SRR6357072_2.fastq.gz,reverse
EOF

echo ""
echo "============================================================================="
echo "✅ Download Complete!"
echo "============================================================================="
echo ""
echo "Files downloaded:"
ls -lh test_data/fastq/
echo ""
echo "Samplesheet created: test_data/samplesheet_real_test.csv"
echo ""
echo "Total size: $(du -sh test_data | cut -f1)"
echo ""
echo "Dataset info:"
echo "  - Organism: Homo sapiens"
echo "  - Library: TruSeq (reverse stranded)"
echo "  - Reads per sample: ~50,000"
echo "  - Read length: 76 bp paired-end"
echo ""
echo "To run the pipeline:"
echo ""
echo "  # Quick test (just alignment, no full quantification)"
echo "  ./scripts/run_local.sh \\"
echo "    -i test_data/samplesheet_real_test.csv \\"
echo "    -g GRCh38 \\"
echo "    -o test_results_real/"
echo ""
echo "  # Or use nextflow directly with more control"
echo "  nextflow run nf-core/rnaseq \\"
echo "    -profile docker \\"
echo "    --input test_data/samplesheet_real_test.csv \\"
echo "    --genome GRCh38 \\"
echo "    --outdir test_results_real/ \\"
echo "    --aligner star_salmon \\"
echo "    --max_memory 16.GB \\"
echo "    --max_cpus 4"
echo ""
echo "Expected runtime: ~45-90 minutes (depending on system)"
echo "============================================================================="
