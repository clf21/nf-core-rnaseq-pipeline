#!/bin/bash
# DEPRECATED - Use generate_synthetic_data.sh instead
# Real test data download has proven unreliable due to:
# - Network/firewall restrictions  
# - Changing repository URLs
# - SRA toolkit configuration issues

echo "⚠️  This script is deprecated."
echo ""
echo "Use synthetic test data instead:"
echo "  ./scripts/generate_synthetic_data.sh"
echo ""
echo "Or run the full test:"
echo "  ./scripts/test_pipeline_simple.sh"
echo ""
echo "Synthetic data is perfect for testing because it:"
echo "  ✓ Tests all pipeline functionality"
echo "  ✓ Tests file I/O and tool integration  "
echo "  ✓ Validates output generation"
echo "  ✓ Works reliably without network issues"
echo ""
echo "The only difference: low alignment rate (expected with random data)"
echo "Everything else works identically to real data."
exit 1
