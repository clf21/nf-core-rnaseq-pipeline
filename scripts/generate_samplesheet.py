#!/usr/bin/env python3
"""
Generate nf-core/rnaseq samplesheet from a directory of FASTQ files.

Usage:
    python generate_samplesheet.py --input_dir /path/to/fastq --output samplesheet.csv --strandedness reverse

This script will:
- Automatically detect paired-end vs single-end reads
- Match R1/R2 or _1/_2 patterns for paired-end
- Generate properly formatted samplesheet CSV
"""

import os
import re
import argparse
from pathlib import Path
from collections import defaultdict


def find_fastq_files(input_dir, pattern=None):
    """Find all FASTQ files in a directory."""
    fastq_extensions = ['.fastq.gz', '.fq.gz', '.fastq', '.fq']
    fastq_files = []
    
    for root, dirs, files in os.walk(input_dir):
        for file in files:
            if any(file.endswith(ext) for ext in fastq_extensions):
                if pattern is None or re.search(pattern, file):
                    fastq_files.append(os.path.join(root, file))
    
    return sorted(fastq_files)


def parse_fastq_pairs(fastq_files):
    """
    Parse FASTQ files and pair R1/R2 reads.
    Returns dict: {sample_name: {'R1': path, 'R2': path or None}}
    """
    samples = defaultdict(dict)
    
    # Common paired-end patterns
    paired_patterns = [
        (r'(.+)_R1(_001)?\.f(ast)?q(\.gz)?$', r'(.+)_R2(_001)?\.f(ast)?q(\.gz)?$'),
        (r'(.+)_1\.f(ast)?q(\.gz)?$', r'(.+)_2\.f(ast)?q(\.gz)?$'),
        (r'(.+)\.R1\.f(ast)?q(\.gz)?$', r'(.+)\.R2\.f(ast)?q(\.gz)?$'),
        (r'(.+)\.1\.f(ast)?q(\.gz)?$', r'(.+)\.2\.f(ast)?q(\.gz)?$'),
    ]
    
    # Try to match paired-end reads
    remaining_files = set(fastq_files)
    
    for r1_pattern, r2_pattern in paired_patterns:
        matched_files = set()
        
        for file1 in remaining_files:
            basename1 = os.path.basename(file1)
            match1 = re.match(r1_pattern, basename1)
            
            if match1:
                sample_name = match1.group(1)
                # Look for corresponding R2
                for file2 in remaining_files:
                    basename2 = os.path.basename(file2)
                    match2 = re.match(r2_pattern, basename2)
                    
                    if match2 and match2.group(1) == sample_name:
                        samples[sample_name]['R1'] = file1
                        samples[sample_name]['R2'] = file2
                        matched_files.add(file1)
                        matched_files.add(file2)
                        break
        
        remaining_files -= matched_files
    
    # Remaining files are single-end
    for file in remaining_files:
        # Extract sample name (remove extension)
        basename = os.path.basename(file)
        sample_name = re.sub(r'\.f(ast)?q(\.gz)?$', '', basename)
        samples[sample_name]['R1'] = file
    
    return samples


def write_samplesheet(samples, output_file, strandedness='auto', s3_prefix=None):
    """Write samplesheet CSV for nf-core/rnaseq."""
    with open(output_file, 'w') as f:
        f.write('sample,fastq_1,fastq_2,strandedness\n')
        
        for sample_name, reads in sorted(samples.items()):
            r1 = reads.get('R1', '')
            r2 = reads.get('R2', '')
            
            # Optionally convert to S3 paths
            if s3_prefix:
                r1 = r1.replace(s3_prefix['local'], s3_prefix['s3'])
                if r2:
                    r2 = r2.replace(s3_prefix['local'], s3_prefix['s3'])
            
            f.write(f'{sample_name},{r1},{r2},{strandedness}\n')
    
    print(f"Samplesheet written to: {output_file}")
    print(f"Total samples: {len(samples)}")
    paired = sum(1 for s in samples.values() if 'R2' in s)
    print(f"Paired-end: {paired}")
    print(f"Single-end: {len(samples) - paired}")


def main():
    parser = argparse.ArgumentParser(
        description='Generate nf-core/rnaseq samplesheet from FASTQ directory'
    )
    parser.add_argument(
        '--input_dir',
        type=str,
        required=True,
        help='Directory containing FASTQ files'
    )
    parser.add_argument(
        '--output',
        type=str,
        default='samplesheet.csv',
        help='Output samplesheet CSV file (default: samplesheet.csv)'
    )
    parser.add_argument(
        '--strandedness',
        type=str,
        default='auto',
        choices=['auto', 'unstranded', 'forward', 'reverse'],
        help='Library strandedness (default: auto)'
    )
    parser.add_argument(
        '--pattern',
        type=str,
        default=None,
        help='Regex pattern to filter FASTQ files (optional)'
    )
    parser.add_argument(
        '--s3_bucket',
        type=str,
        default=None,
        help='Convert local paths to S3 paths (e.g., s3://my-bucket/fastq)'
    )
    parser.add_argument(
        '--local_prefix',
        type=str,
        default=None,
        help='Local path prefix to replace with S3 bucket path'
    )
    
    args = parser.parse_args()
    
    # Find FASTQ files
    print(f"Scanning directory: {args.input_dir}")
    fastq_files = find_fastq_files(args.input_dir, args.pattern)
    
    if not fastq_files:
        print("ERROR: No FASTQ files found!")
        return
    
    print(f"Found {len(fastq_files)} FASTQ files")
    
    # Parse paired/single-end
    samples = parse_fastq_pairs(fastq_files)
    
    # Setup S3 conversion if needed
    s3_prefix = None
    if args.s3_bucket and args.local_prefix:
        s3_prefix = {
            'local': args.local_prefix,
            's3': args.s3_bucket
        }
    
    # Write samplesheet
    write_samplesheet(samples, args.output, args.strandedness, s3_prefix)


if __name__ == '__main__':
    main()
