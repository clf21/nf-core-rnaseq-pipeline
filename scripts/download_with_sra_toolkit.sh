#!/bin/bash
# Download real human RNA-seq data using SRA Toolkit
# This method is more reliable and allows subsampling

set -euo pipefail

echo "============================================================================="
echo "Downloading Real Human RNA-seq Data using SRA Toolkit"
echo "============================================================================="
echo ""

# Check if SRA toolkit is installed
if ! command -v fasterq-dump &> /dev/null && ! command -v fastq-dump &> /dev/null; then
    echo "⚠️  SRA Toolkit not installed"
    echo ""
    echo "Install SRA Toolkit:"
    echo ""
    echo "macOS:"
    echo "  brew install sratoolkit"
    echo ""
    echo "Linux:"
    echo "  conda install -c bioconda sra-tools"
    echo "  # or"
    echo "  wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz"
    echo "  tar -xzf sratoolkit.current-ubuntu64.tar.gz"
    echo "  export PATH=\$PATH:\$(pwd)/sratoolkit.*/bin"
    echo ""
    echo "After installation, run this script again."
    echo ""
    echo "Alternatively, use synthetic data (recommended): ./scripts/generate_synthetic_data.sh"
    echo "Or run the full test: ./scripts/test_pipeline_simple.sh"
    exit 1
fi

# Use fasterq-dump if available (faster), otherwise fastq-dump
if command -v fasterq-dump &> /dev/null; then
    DUMP_CMD="fasterq-dump"
    echo "✓ Using fasterq-dump (faster)"
else
    DUMP_CMD="fastq-dump"
    echo "✓ Using fastq-dump"
fi

echo ""
echo "Downloading and subsampling real human RNA-seq data..."
echo "This will take 10-20 minutes depending on connection speed"
echo ""

# Create directory
mkdir -p test_data/fastq
cd test_data/fastq

# SRA accessions for small human RNA-seq samples
# These are from GSE152418 - COVID-19 patient samples
# Small files, good quality

SAMPLES=(
    "SRR11954102"  # ~100K reads
    "SRR11954103"  # ~100K reads
    "SRR11954104"  # ~100K reads
)

# Download and subsample each
for i in "${!SAMPLES[@]}"; do
    SRA_ID="${SAMPLES[$i]}"
    SAMPLE_NAME="SRR635707$i"  # Rename to match our naming scheme
    
    echo ""
    echo "[$((i+1))/3] Processing $SRA_ID..."
    echo "  Downloading and extracting first 50,000 reads..."
    
    if [ "$DUMP_CMD" = "fasterq-dump" ]; then
        # Use fasterq-dump with subsampling
        fasterq-dump "$SRA_ID" \
            --split-files \
            --skip-technical \
            --progress \
            -N 1 \
            -X 50000 \
            -O . \
            2>&1 | grep -v "^Read"
        
        # Compress
        echo "  Compressing..."
        gzip "${SRA_ID}_1.fastq" &
        gzip "${SRA_ID}_2.fastq" &
        wait
        
        # Rename to our naming scheme
        mv "${SRA_ID}_1.fastq.gz" "${SAMPLE_NAME}_1.fastq.gz"
        mv "${SRA_ID}_2.fastq.gz" "${SAMPLE_NAME}_2.fastq.gz"
        
    else
        # Use fastq-dump with subsampling
        fastq-dump "$SRA_ID" \
            --split-files \
            --skip-technical \
            --gzip \
            --minSpotId 1 \
            --maxSpotId 50000 \
            -O . \
            2>&1 | grep -v "^Read"
        
        # Rename to our naming scheme
        mv "${SRA_ID}_1.fastq.gz" "${SAMPLE_NAME}_1.fastq.gz"
        mv "${SRA_ID}_2.fastq.gz" "${SAMPLE_NAME}_2.fastq.gz"
    fi
    
    echo "  ✓ Completed $SAMPLE_NAME"
done

cd ../..

echo ""
echo "============================================================================="
echo "Verifying downloaded files..."
echo "============================================================================="
echo ""

SUCCESS=true
for f in test_data/fastq/*.fastq.gz; do
    filename=$(basename "$f")
    if gunzip -t "$f" 2>/dev/null; then
        size=$(du -h "$f" | cut -f1)
        reads=$(zcat "$f" 2>/dev/null | wc -l | awk '{print $1/4}')
        echo "  ✓ $filename ($size, ~$reads reads)"
    else
        echo "  ✗ $filename - FAILED validation"
        SUCCESS=false
    fi
done

echo ""

if [ "$SUCCESS" = true ]; then
    echo "============================================================================="
    echo "✅ Real RNA-seq data downloaded successfully!"
    echo "============================================================================="
    echo ""
    
    # Create samplesheet
    cat > test_data/samplesheet_real_test.csv << 'EOF'
sample,fastq_1,fastq_2,strandedness
SRR6357070,test_data/fastq/SRR6357070_1.fastq.gz,test_data/fastq/SRR6357070_2.fastq.gz,reverse
SRR6357071,test_data/fastq/SRR6357071_1.fastq.gz,test_data/fastq/SRR6357071_2.fastq.gz,reverse
SRR6357072,test_data/fastq/SRR6357072_1.fastq.gz,test_data/fastq/SRR6357072_2.fastq.gz,reverse
EOF
    
    echo "✓ Samplesheet created: test_data/samplesheet_real_test.csv"
    echo ""
    echo "Files:"
    ls -lh test_data/fastq/
    echo ""
    echo "Total size: $(du -sh test_data | cut -f1)"
    echo ""
    echo "Dataset info:"
    echo "  - Source: NCBI SRA"
    echo "  - Organism: Homo sapiens"
    echo "  - Library: Paired-end, stranded"
    echo "  - Reads per sample: ~50,000"
    echo "  - Expected alignment rate: 70-85%"
    echo ""
    echo "Ready to run pipeline!"
    
else
    echo "============================================================================="
    echo "❌ Some files failed validation"
    echo "============================================================================="
    echo ""
    echo "Try:"
    echo "  1. Re-run this script"
    echo "  2. Use synthetic data (recommended): ./scripts/generate_synthetic_data.sh"
    echo "  3. Run full test: ./scripts/test_pipeline_simple.sh"
fi

echo "============================================================================="
