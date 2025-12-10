#!/bin/bash
# Download minimal human genome reference for testing
# Uses only chromosome 22 to keep download small and fast

set -euo pipefail

echo "============================================================================="
echo "Downloading Minimal Test Genome (Human Chromosome 22)"
echo "============================================================================="
echo ""
echo "This downloads a small genome reference for quick testing:"
echo "  - Human chromosome 22 only (~51 Mb)"
echo "  - GTF annotation for chr22"
echo "  - Much faster than full genome"
echo ""

# Create directory
mkdir -p test_genome
cd test_genome

echo "Downloading chromosome 22 FASTA..."
if [ ! -f "Homo_sapiens.GRCh38.dna.chromosome.22.fa.gz" ]; then
    curl -L -o Homo_sapiens.GRCh38.dna.chromosome.22.fa.gz \
        "ftp://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.chromosome.22.fa.gz"
    gunzip Homo_sapiens.GRCh38.dna.chromosome.22.fa.gz
else
    echo "✓ FASTA already exists"
fi

echo "Downloading GTF annotation..."
if [ ! -f "Homo_sapiens.GRCh38.110.chr22.gtf.gz" ]; then
    curl -L -o Homo_sapiens.GRCh38.110.gtf.gz \
        "ftp://ftp.ensembl.org/pub/release-110/gtf/homo_sapiens/Homo_sapiens.GRCh38.110.gtf.gz"
    
    # Extract only chr22 annotations
    echo "Extracting chr22 annotations..."
    gunzip -c Homo_sapiens.GRCh38.110.gtf.gz | grep "^22" > Homo_sapiens.GRCh38.110.chr22.gtf
    rm Homo_sapiens.GRCh38.110.gtf.gz
else
    echo "✓ GTF already exists"
fi

cd ..

echo ""
echo "============================================================================="
echo "✅ Test Genome Downloaded!"
echo "============================================================================="
echo ""
echo "Files created:"
ls -lh test_genome/
echo ""
echo "Total size: $(du -sh test_genome | cut -f1)"
echo ""
echo "To run pipeline with this genome:"
echo ""
echo "  nextflow run nf-core/rnaseq \\"
echo "    -profile docker \\"
echo "    --input test_data/samplesheet_real_test.csv \\"
echo "    --fasta test_genome/Homo_sapiens.GRCh38.dna.chromosome.22.fa \\"
echo "    --gtf test_genome/Homo_sapiens.GRCh38.110.chr22.gtf \\"
echo "    --outdir test_results/ \\"
echo "    --max_memory 8.GB \\"
echo "    --max_cpus 4"
echo ""
echo "Note: Alignment rates will be lower since only chr22 is present"
echo "      This is normal for testing purposes"
echo "============================================================================="
