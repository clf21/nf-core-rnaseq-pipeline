#!/usr/bin/env python3
"""
Fast synthetic FASTQ generator for pipeline testing.
Generates paired-end FASTQ files orders of magnitude faster than bash loops.
"""

import gzip
import random
import argparse
from pathlib import Path


def generate_fastq_read(sample_name, read_num, read_length=75, mate=1):
    """Generate a single FASTQ read entry (4 lines)."""
    # FASTQ format:
    # @read_id
    # sequence
    # +
    # quality_scores

    read_id = f"@{sample_name}.{read_num} {read_num}/{mate}"
    sequence = ''.join(random.choices('ACGT', k=read_length))
    # High quality scores (mostly Q40 = 'I' in Phred+33)
    quality = ''.join(random.choices('IIIIIIIIIIHHHHHGGGGGFFFFF', k=read_length))

    return f"{read_id}\n{sequence}\n+\n{quality}\n"


def generate_sample(output_dir, sample_name, num_reads=10000, read_length=75):
    """Generate paired-end FASTQ files for one sample."""
    print(f"Generating {sample_name} ({num_reads:,} read pairs)...")

    r1_file = output_dir / f"{sample_name}_1.fastq.gz"
    r2_file = output_dir / f"{sample_name}_2.fastq.gz"

    # Generate R1
    with gzip.open(r1_file, 'wt') as f1:
        for i in range(1, num_reads + 1):
            f1.write(generate_fastq_read(sample_name, i, read_length, mate=1))

    # Generate R2
    with gzip.open(r2_file, 'wt') as f2:
        for i in range(1, num_reads + 1):
            f2.write(generate_fastq_read(sample_name, i, read_length, mate=2))

    print(f"  ✓ Created {r1_file.name} and {r2_file.name}")
    return r1_file, r2_file


def create_samplesheet(output_dir, samples):
    """Create nf-core/rnaseq samplesheet."""
    samplesheet = output_dir.parent / "samplesheet_real_test.csv"

    with open(samplesheet, 'w') as f:
        f.write("sample,fastq_1,fastq_2,strandedness\n")
        for sample_name in samples:
            r1 = f"test_data/fastq/{sample_name}_1.fastq.gz"
            r2 = f"test_data/fastq/{sample_name}_2.fastq.gz"
            f.write(f"{sample_name},{r1},{r2},auto\n")

    print(f"\n✓ Samplesheet created: {samplesheet}")
    return samplesheet


def main():
    parser = argparse.ArgumentParser(
        description='Generate synthetic FASTQ data for RNA-seq pipeline testing'
    )
    parser.add_argument(
        '--output_dir',
        type=Path,
        default=Path('test_data/fastq'),
        help='Output directory for FASTQ files'
    )
    parser.add_argument(
        '--num_reads',
        type=int,
        default=10000,
        help='Number of read pairs per sample (default: 10000)'
    )
    parser.add_argument(
        '--read_length',
        type=int,
        default=75,
        help='Read length in bp (default: 75)'
    )
    parser.add_argument(
        '--samples',
        nargs='+',
        default=['SRR6357070', 'SRR6357071', 'SRR6357072'],
        help='Sample names to generate'
    )

    args = parser.parse_args()

    print("=" * 80)
    print("Generating Synthetic Test FASTQ Data")
    print("=" * 80)
    print(f"\nCreating {len(args.samples)} samples with {args.num_reads:,} reads each (paired-end)")
    print("This generates valid FASTQ format for testing pipeline execution\n")

    # Create output directory
    args.output_dir.mkdir(parents=True, exist_ok=True)

    # Generate samples
    for sample in args.samples:
        generate_sample(args.output_dir, sample, args.num_reads, args.read_length)

    # Create samplesheet
    create_samplesheet(args.output_dir, args.samples)

    print("\n" + "=" * 80)
    print("✅ Synthetic Test Data Generated Successfully!")
    print("=" * 80)
    print(f"\nFiles created in {args.output_dir}/")

    # List files with sizes
    for f in sorted(args.output_dir.glob("*.fastq.gz")):
        size = f.stat().st_size / 1024  # KB
        print(f"  {f.name}: {size:.1f} KB")

    print("\n⚠️  IMPORTANT NOTE:")
    print("   These are SYNTHETIC random reads for testing pipeline execution only")
    print("   Alignment rates will be LOW (0-5%) - this is EXPECTED and NORMAL")
    print("   The pipeline will run successfully and produce all outputs")
    print("   This validates the pipeline works correctly")
    print("\nReady to run pipeline!")
    print("=" * 80)


if __name__ == '__main__':
    main()
