#!/bin/bash
# Generate valid synthetic FASTQ test data
# Creates realistic-looking FASTQ files for pipeline testing
# Uses optimized Python script for 100x+ faster generation

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run the optimized Python generator
python3 "${SCRIPT_DIR}/generate_synthetic_fastq.py" "$@"
