#!/bin/bash
# Generate minimal test FASTQ files for pipeline testing
# These are synthetic reads - just for testing pipeline functionality

set -euo pipefail

echo "Generating minimal test FASTQ files..."

# Create test data directory
mkdir -p test_data/fastq

# Function to generate random DNA sequence
generate_seq() {
    local length=$1
    cat /dev/urandom | LC_ALL=C tr -dc 'ACGT' | fold -w ${length} | head -n 1
}

# Function to generate quality scores
generate_qual() {
    local length=$1
    python3 -c "print('I' * ${length})"  # Quality score 40
}

# Generate minimal paired-end FASTQ files (1000 reads per sample)
generate_fastq_pair() {
    local sample=$1
    local num_reads=${2:-1000}
    local read_length=75
    
    echo "Generating ${sample}..."
    
    # R1 file
    for i in $(seq 1 $num_reads); do
        echo "@${sample}_read${i}/1"
        generate_seq $read_length
        echo "+"
        generate_qual $read_length
    done | gzip > test_data/fastq/${sample}_R1.fastq.gz
    
    # R2 file
    for i in $(seq 1 $num_reads); do
        echo "@${sample}_read${i}/2"
        generate_seq $read_length
        echo "+"
        generate_qual $read_length
    done | gzip > test_data/fastq/${sample}_R2.fastq.gz
}

# Generate 3 test samples (2 control, 1 treatment)
generate_fastq_pair "CTRL_01" 1000
generate_fastq_pair "CTRL_02" 1000
generate_fastq_pair "TREAT_01" 1000

# Create samplesheet
cat > test_data/samplesheet_test.csv << 'EOF'
sample,fastq_1,fastq_2,strandedness
CTRL_01,test_data/fastq/CTRL_01_R1.fastq.gz,test_data/fastq/CTRL_01_R2.fastq.gz,auto
CTRL_02,test_data/fastq/CTRL_02_R1.fastq.gz,test_data/fastq/CTRL_02_R2.fastq.gz,auto
TREAT_01,test_data/fastq/TREAT_01_R1.fastq.gz,test_data/fastq/TREAT_01_R2.fastq.gz,auto
EOF

echo ""
echo "✅ Test data generated successfully!"
echo ""
echo "Files created:"
ls -lh test_data/fastq/
echo ""
echo "Samplesheet created: test_data/samplesheet_test.csv"
echo ""
echo "Total size: $(du -sh test_data | cut -f1)"
echo ""
echo "⚠️  NOTE: This is SYNTHETIC data for testing only!"
echo "    The reads are random and won't align well to real genomes."
echo "    Use nf-core test profile for realistic test data."
echo ""
echo "To run with this data:"
echo "  ./scripts/run_local.sh -i test_data/samplesheet_test.csv -g GRCh38 -o test_results/"
