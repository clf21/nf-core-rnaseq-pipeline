# Downstream Analysis Example
# Using nf-core RNA-seq outputs with DESeq2

# This script demonstrates how to:
# 1. Import Salmon quantification data using tximport
# 2. Run differential expression analysis with DESeq2
# 3. Generate visualizations

# Required packages
# install.packages("BiocManager")
# BiocManager::install(c("DESeq2", "tximport", "apeglm", "ggplot2", "pheatmap", "EnhancedVolcano"))

library(tximport)
library(DESeq2)
library(ggplot2)
library(pheatmap)

# ==============================================================================
# 1. Import Salmon Data
# ==============================================================================

# Set up file paths
results_dir <- "results/star_salmon"

# Create sample metadata
samples <- data.frame(
  sample = c("CTRL_01", "CTRL_02", "CTRL_03", "TREAT_01", "TREAT_02", "TREAT_03"),
  condition = c("control", "control", "control", "treatment", "treatment", "treatment"),
  row.names = "sample"
)

# Salmon quant.sf files
files <- file.path(results_dir, rownames(samples), "quant.sf")
names(files) <- rownames(samples)

# Load transcript-to-gene mapping
# This is from the GTF file used in the pipeline
# Can extract from: results/star_salmon/tx2gene.tsv (if saved)
tx2gene <- read.table(
  file.path(results_dir, "salmon_tx2gene.tsv"),
  header = FALSE,
  col.names = c("transcript_id", "gene_id")
)

# Import Salmon data
txi <- tximport(
  files,
  type = "salmon",
  tx2gene = tx2gene,
  ignoreTxVersion = TRUE,
  countsFromAbundance = "lengthScaledTPM"  # Recommended for DESeq2
)

# Alternatively, use pre-merged counts from pipeline
# gene_counts <- read.table(
#   file.path(results_dir, "salmon.merged.gene_counts.tsv"),
#   header = TRUE,
#   row.names = 1
# )

# ==============================================================================
# 2. Create DESeq2 Dataset
# ==============================================================================

# Create DESeq2 object
dds <- DESeqDataSetFromTximport(
  txi,
  colData = samples,
  design = ~ condition
)

# Pre-filtering: remove genes with very low counts
keep <- rowSums(counts(dds)) >= 10
dds <- dds[keep,]

# Set reference level (control as baseline)
dds$condition <- relevel(dds$condition, ref = "control")

# ==============================================================================
# 3. Run Differential Expression Analysis
# ==============================================================================

# Run DESeq2 pipeline
dds <- DESeq(dds)

# Extract results
res <- results(
  dds,
  contrast = c("condition", "treatment", "control"),
  alpha = 0.05
)

# Shrink log2 fold changes (for visualization)
res_shrunk <- lfcShrink(
  dds,
  coef = "condition_treatment_vs_control",
  type = "apeglm"
)

# Summary
summary(res)

# How many differentially expressed genes?
sum(res$padj < 0.05, na.rm = TRUE)

# ==============================================================================
# 4. Extract and Save Results
# ==============================================================================

# Convert to data frame and order by adjusted p-value
res_df <- as.data.frame(res)
res_df <- res_df[order(res_df$padj),]

# Add gene symbols (if available in annotation)
# This requires biomaRt or local annotation file
# Example:
# library(biomaRt)
# mart <- useEnsembl("ensembl", dataset = "hsapiens_gene_ensembl")
# genes <- getBM(
#   attributes = c("ensembl_gene_id", "external_gene_name"),
#   filters = "ensembl_gene_id",
#   values = rownames(res_df),
#   mart = mart
# )
# res_df <- merge(res_df, genes, by.x = "row.names", by.y = "ensembl_gene_id")

# Save results
write.csv(res_df, "DESeq2_results_treatment_vs_control.csv")

# Save significant genes (FDR < 0.05)
sig_genes <- subset(res_df, padj < 0.05)
write.csv(sig_genes, "DESeq2_significant_genes.csv")

# ==============================================================================
# 5. Visualizations
# ==============================================================================

# ---- PCA Plot ----
vsd <- vst(dds, blind = FALSE)

pcaData <- plotPCA(vsd, intgroup = "condition", returnData = TRUE)
percentVar <- round(100 * attr(pcaData, "percentVar"))

ggplot(pcaData, aes(PC1, PC2, color = condition)) +
  geom_point(size = 3) +
  xlab(paste0("PC1: ", percentVar[1], "% variance")) +
  ylab(paste0("PC2: ", percentVar[2], "% variance")) +
  theme_minimal() +
  theme(legend.position = "top")

ggsave("PCA_plot.pdf", width = 6, height = 5)

# ---- MA Plot ----
pdf("MA_plot.pdf", width = 8, height = 6)
plotMA(res_shrunk, ylim = c(-5, 5))
dev.off()

# ---- Volcano Plot ----
library(EnhancedVolcano)

EnhancedVolcano(
  res_df,
  lab = rownames(res_df),
  x = 'log2FoldChange',
  y = 'padj',
  title = 'Treatment vs Control',
  pCutoff = 0.05,
  FCcutoff = 1.0,
  pointSize = 2.0,
  labSize = 3.0
)

ggsave("volcano_plot.pdf", width = 10, height = 8)

# ---- Heatmap of Top Genes ----
# Select top 50 differentially expressed genes
top_genes <- head(order(res$padj), 50)

# Get normalized counts
mat <- assay(vsd)[top_genes,]

# Scale by row (gene)
mat <- t(scale(t(mat)))

# Create annotation for samples
annotation_col <- data.frame(
  Condition = samples$condition,
  row.names = rownames(samples)
)

# Plot heatmap
pheatmap(
  mat,
  annotation_col = annotation_col,
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  show_rownames = FALSE,
  show_colnames = TRUE,
  main = "Top 50 Differentially Expressed Genes",
  filename = "heatmap_top50.pdf",
  width = 7,
  height = 8
)

# ---- Sample Distance Matrix ----
sampleDists <- dist(t(assay(vsd)))
sampleDistMatrix <- as.matrix(sampleDists)

pheatmap(
  sampleDistMatrix,
  clustering_distance_rows = sampleDists,
  clustering_distance_cols = sampleDists,
  main = "Sample-to-Sample Distances",
  filename = "sample_distances.pdf",
  width = 7,
  height = 6
)

# ---- Count Plots for Top Genes ----
pdf("top_gene_counts.pdf", width = 10, height = 8)
par(mfrow = c(2, 2))

for (i in 1:4) {
  gene_id <- rownames(res_df)[i]
  plotCounts(dds, gene = gene_id, intgroup = "condition", main = gene_id)
}

dev.off()

# ==============================================================================
# 6. Gene Set Enrichment Analysis (Optional)
# ==============================================================================

# Prepare gene list for GSEA
gene_list <- res_df$log2FoldChange
names(gene_list) <- rownames(res_df)
gene_list <- na.omit(gene_list)
gene_list <- sort(gene_list, decreasing = TRUE)

# Example with clusterProfiler (requires installation)
# library(clusterProfiler)
# library(org.Hs.eg.db)
#
# # Convert to Entrez IDs
# genes_entrez <- bitr(
#   names(gene_list),
#   fromType = "ENSEMBL",
#   toType = "ENTREZID",
#   OrgDb = org.Hs.eg.db
# )
#
# # Run GSEA
# gsea_results <- gseGO(
#   geneList = gene_list,
#   OrgDb = org.Hs.eg.db,
#   ont = "BP",
#   minGSSize = 10,
#   maxGSSize = 500,
#   pvalueCutoff = 0.05
# )

# ==============================================================================
# Session Info (for reproducibility)
# ==============================================================================

sink("session_info.txt")
sessionInfo()
sink()

cat("
Analysis complete!

Generated files:
  - DESeq2_results_treatment_vs_control.csv
  - DESeq2_significant_genes.csv
  - PCA_plot.pdf
  - MA_plot.pdf
  - volcano_plot.pdf
  - heatmap_top50.pdf
  - sample_distances.pdf
  - top_gene_counts.pdf
  - session_info.txt
")
