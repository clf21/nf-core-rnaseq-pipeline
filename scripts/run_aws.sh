#!/bin/bash
# Run nf-core/rnaseq pipeline on AWS Batch

set -euo pipefail

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run nf-core/rnaseq pipeline on AWS Batch.

Required Arguments:
  -i, --input FILE         Path to samplesheet CSV (local or S3)
  -g, --genome STR         Genome assembly (GRCh38, GRCm39, etc.)
  -o, --outdir S3_PATH     Output S3 path (e.g., s3://bucket/results)

Optional Arguments:
  -q, --queue STR          AWS Batch queue name
  -w, --workdir S3_PATH    S3 work directory (default: s3://bucket/work)
  -s, --strandedness STR   Library strandedness (auto|unstranded|forward|reverse)
                           Default: auto
  -p, --profile STR        Nextflow profile (aws|aws_large_scale)
                           Default: aws
  -r, --resume             Resume previous run
  -h, --help               Show this help message

Examples:
  # Standard AWS run with 10 samples
  $0 -i samplesheet.csv -g GRCh38 -o s3://my-bucket/results

  # Large-scale run with 500 samples
  $0 -i samplesheet.csv -g GRCh38 -o s3://my-bucket/results -p aws_large_scale

  # Resume previous run
  $0 -i samplesheet.csv -g GRCh38 -o s3://my-bucket/results --resume

Notes:
  • Ensure AWS credentials are configured (aws configure)
  • Samplesheet can reference local or S3 FASTQ paths
  • AWS Batch queue must be created first (see setup_aws_batch.sh)

EOF
    exit 1
}

# Default values
RESUME=""
STRANDEDNESS="auto"
PROFILE="aws"
WORKDIR=""
QUEUE=""

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
        -q|--queue)
            QUEUE="$2"
            shift 2
            ;;
        -w|--workdir)
            WORKDIR="$2"
            shift 2
            ;;
        -s|--strandedness)
            STRANDEDNESS="$2"
            shift 2
            ;;
        -p|--profile)
            PROFILE="$2"
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

# Check if input exists (local or S3)
if [[ "$INPUT" == s3://* ]]; then
    if ! aws s3 ls "$INPUT" &> /dev/null; then
        echo "ERROR: Samplesheet not found in S3: $INPUT"
        exit 1
    fi
else
    if [ ! -f "$INPUT" ]; then
        echo "ERROR: Samplesheet not found: $INPUT"
        exit 1
    fi
fi

# Validate S3 output path
if [[ "$OUTDIR" != s3://* ]]; then
    echo "ERROR: Output directory must be an S3 path (e.g., s3://bucket/results)"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi

echo "=============================================================================
Running nf-core/rnaseq Pipeline (AWS Batch)
=============================================================================
Input:        $INPUT
Genome:       $GENOME
Output:       $OUTDIR
Profile:      $PROFILE
Strandedness: $STRANDEDNESS
Resume:       ${RESUME:-No}
============================================================================="

# Build command
CMD="nextflow run nf-core/rnaseq \
    -profile $PROFILE \
    -c nextflow.config \
    $RESUME \
    --input $INPUT \
    --genome $GENOME \
    --outdir $OUTDIR \
    --strandedness $STRANDEDNESS \
    --aligner star_salmon"

# Add optional parameters
if [ -n "$QUEUE" ]; then
    CMD="$CMD --process.queue $QUEUE"
fi

if [ -n "$WORKDIR" ]; then
    CMD="$CMD -w $WORKDIR"
fi

# Execute
eval $CMD

echo "
=============================================================================
Pipeline Submitted to AWS Batch!
=============================================================================
Monitor progress:
  • Nextflow Tower: https://tower.nf
  • AWS Batch Console: https://console.aws.amazon.com/batch/
  
Results will be written to: $OUTDIR

Key outputs:
  • MultiQC report: $OUTDIR/multiqc/star_salmon/multiqc_report.html
  • Gene counts: $OUTDIR/star_salmon/salmon.merged.gene_counts.tsv
  • Transcript counts: $OUTDIR/star_salmon/salmon.merged.transcript_counts.tsv

To download results:
  aws s3 sync $OUTDIR ./local_results/
============================================================================="
