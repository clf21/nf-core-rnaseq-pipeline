#!/bin/bash
# Run nf-core/rnaseq pipeline locally with Docker

set -euo pipefail

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run nf-core/rnaseq pipeline locally using Docker containers.

Required Arguments:
  -i, --input FILE         Path to samplesheet CSV
  -g, --genome STR         Genome assembly (GRCh38, GRCm39, etc.)
  -o, --outdir DIR         Output directory path

Optional Arguments:
  -s, --strandedness STR   Library strandedness (auto|unstranded|forward|reverse)
                           Default: auto
  -r, --resume             Resume previous run
  -h, --help               Show this help message

Examples:
  # Human RNA-seq with paired-end reads
  $0 -i samplesheet.csv -g GRCh38 -o results/

  # Mouse RNA-seq with resume
  $0 -i samplesheet.csv -g GRCm39 -o results/ --resume

  # Specify strandedness
  $0 -i samplesheet.csv -g GRCh38 -o results/ -s reverse

EOF
    exit 1
}

# Default values
RESUME=""
STRANDEDNESS="auto"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            INPUT="$2"
            shift 2
            ;;
        -g|--genome)
            GENOME="$2"
            shift 2
            ;;
        -o|--outdir)
            OUTDIR="$2"
            shift 2
            ;;
        -s|--strandedness)
            STRANDEDNESS="$2"
            shift 2
            ;;
        -r|--resume)
            RESUME="-resume"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check required arguments
if [ -z "${INPUT:-}" ] || [ -z "${GENOME:-}" ] || [ -z "${OUTDIR:-}" ]; then
    echo "ERROR: Missing required arguments"
    usage
fi

# Check if samplesheet exists
if [ ! -f "$INPUT" ]; then
    echo "ERROR: Samplesheet not found: $INPUT"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "ERROR: Docker is not running or not accessible"
    exit 1
fi

# Create output directory
mkdir -p "$OUTDIR"

echo "=============================================================================
Running nf-core/rnaseq Pipeline (Local)
=============================================================================
Input:        $INPUT
Genome:       $GENOME
Output:       $OUTDIR
Strandedness: $STRANDEDNESS
Resume:       ${RESUME:-No}
============================================================================="

# Run the pipeline
nextflow run nf-core/rnaseq \
    -profile local \
    -c nextflow.config \
    $RESUME \
    --input "$INPUT" \
    --genome "$GENOME" \
    --outdir "$OUTDIR" \
    --strandedness "$STRANDEDNESS" \
    --aligner star_salmon \
    --save_reference false \
    --max_cpus 8 \
    --max_memory 32.GB

echo "
=============================================================================
Pipeline Complete!
=============================================================================
Results are in: $OUTDIR

Key outputs:
  • MultiQC report: $OUTDIR/multiqc/star_salmon/multiqc_report.html
  • Gene counts: $OUTDIR/star_salmon/salmon.merged.gene_counts.tsv
  • Transcript counts: $OUTDIR/star_salmon/salmon.merged.transcript_counts.tsv
  • BAM files: $OUTDIR/star_salmon/*.bam
============================================================================="
