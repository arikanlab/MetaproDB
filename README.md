# MetaproDB

**MetaproDB** is a framework for biome-informed metaproteomic database construction. It combines an R package for planning database builds with a Snakemake workflow for downloading, rehydrating, extracting, and assembling protein sequence databases.

MetaproDB is designed to support reproducible and transparent construction of metaproteomic search databases using ecological information. Instead of relying only on very large generic databases or matched metagenomes, MetaproDB enables users to build context-aware protein databases from curated biome resources or user-provided microbiome data.

## Overview

MetaproDB supports two main use cases:

- building a database from one of the **bundled curated biome resources**
- building a database from a **user-provided phyloseq object**

The workflow always has two stages:

1. **plan the build in R**
2. **run the build with Snakemake**

The R package is responsible for:

- loading bundled biome resources
- summarizing biome content
- ranking and selecting taxa
- defining core taxa
- generating genus manifests and build plans
- writing Snakemake configuration files
- producing QC and provenance summaries

The Snakemake workflow is responsible for:

- downloading genome resource archives for genera marked as requiring download in the build plan
- rehydrating genome packages
- extracting protein FASTA files
- merging selected proteins into a database
- deduplicating sequences
- producing final database outputs

## Main features

- Bundled curated biome resources for database planning
- Support for user-provided `phyloseq` objects
- Taxon selection using **top-N abundance** and optional **core taxa** inclusion
- Genome manifest generation for selected genera
- Snakemake-based execution workflow
- Optional host proteome merging
- Post-build QC summaries
- Provenance reporting for reproducibility

## Installation

MetaproDB has two components that work together:

1. an **R package** for biome loading, taxon selection, manifest generation, and workflow planning  
2. a **Snakemake workflow** for database construction

These components have different dependency layers:

- **R package dependencies** are declared in `DESCRIPTION`
- **workflow/tool dependencies** are declared in `workflow/envs/metaprodb.yml`

### 1. Clone the repository

```bash
git clone https://github.com/arikanlab/MetaproDB.git
cd MetaproDB
```

### 2. Create and activate the workflow environment

Create the conda environment used by the Snakemake workflow:

```bash
conda env create -f workflow/envs/metaprodb.yml
conda activate metaprodb
```

This environment installs the main workflow tools, including:

- `snakemake`
- `ncbi-datasets-cli`
- `seqkit`

### 3. Install the R package

Start R from the repository root and install the package:

```r
install.packages("devtools")
devtools::install(".")
```

This installs the R package together with the dependencies listed in `DESCRIPTION`.

### 4. Confirm required command-line tools are available

In the activated conda environment, confirm that the workflow tools are available:

```bash
which snakemake
which datasets
which seqkit
```

You should also be able to run:

```bash
datasets --version
seqkit version
```

### 5. Recommended conda configuration

For more reliable dependency resolution:

```bash
conda config --set channel_priority strict
```

### 6. Run the workflow smoke test

After installation, run:

```bash
bash tests/workflow/smoke_test.sh
```

This runs a small cache-mode workflow test using local fixture genome archives and checks that the expected output files are produced.

## Inputs

MetaproDB can be used with either of the following input types:

### 1. Bundled curated biome resources

MetaproDB includes bundled biome objects together with metadata describing the curated biome panel. These resources can be used directly for taxon selection and database planning.

### 2. User-provided `phyloseq` objects

Users can provide their own `phyloseq` objects and construct a database tailored to their study.

## Basic usage

MetaproDB always works in two steps:

1. **plan the build in R**
2. **run the build with Snakemake**

The examples below assume you are running from the **repository root**, where bundled resources such as `resources/genus_index.tsv` and `resources/genomes/` are available.

## Bundled biome workflow

Use one of the bundled curated biome resources included in MetaproDB.

### Step 1: plan the build in R

```r
library(metaprodb)

genus_index <- read_genus_index("resources/genus_index.tsv")

res <- plan_build_from_biome(
  biome_id = "saliva",
  genus_index_tbl = genus_index,
  resource_dir = "resources/genomes",
  top_n = 20,
  include_core = TRUE,
  prevalence = 0.5,
  abundance = 0.01,
  write_plan = TRUE
)
```

This creates a build plan and writes the workflow files needed to run database construction. The returned object `res` contains the selected taxa, build plan information, and paths to generated files.

The build plan records, for each selected genus, expected resource files and workflow status fields such as whether download is required and whether the genus is ready to build.

Typical generated files include:

- `results/database_builds/saliva/saliva_build_plan.tsv`
- `results/database_builds/saliva/saliva_snakemake_config.yml`

### Step 2: run the workflow

```bash
snakemake -s workflow/Snakefile \
  --configfile results/database_builds/saliva/saliva_snakemake_config.yml \
  --cores 4 \
  --use-conda
```

### Main outputs

Typical outputs include:

- `results/database_builds/saliva/MetaproDB_saliva.faa`
- `results/database_builds/saliva/MetaproDB_saliva.manifest.tsv`

## Custom phyloseq workflow

Use a user-provided phyloseq object to build a database tailored to that dataset.

### Step 1: plan the build in R

```r
library(metaprodb)

ps <- readRDS("my_phyloseq.rds")

res <- plan_build_from_phyloseq(
  ps = ps,
  biome_id = "my_microbiome",
  resource_dir = "resources/genomes",
  top_n = 20,
  include_core = TRUE,
  prevalence = 0.5,
  abundance = 0.01,
  write_plan = TRUE
)
```

This creates a build plan and writes the workflow files needed to run database construction. The returned object `res` contains the selected taxa, build plan information, and paths to generated files.

The build plan records, for each selected genus, expected resource files and workflow status fields such as whether download is required and whether the genus is ready to build.

Typical generated files include:

- `results/database_builds/my_microbiome/my_microbiome_build_plan.tsv`
- `results/database_builds/my_microbiome/my_microbiome_snakemake_config.yml`

### Step 2: run the workflow

```bash
snakemake -s workflow/Snakefile \
  --configfile results/database_builds/my_microbiome/my_microbiome_snakemake_config.yml \
  --cores 4 \
  --use-conda
```

### Main outputs

Typical outputs include:

- `results/database_builds/my_microbiome/MetaproDB_my_microbiome.faa`
- `results/database_builds/my_microbiome/MetaproDB_my_microbiome.manifest.tsv`

## Optional host proteome support

MetaproDB does **not** download host proteomes automatically. To include host proteins, provide a user-supplied host FASTA in the generated Snakemake config file.

For example, edit:

```text
results/database_builds/saliva/saliva_snakemake_config.yml
```

and set:

```yaml
host_proteome: path/to/host_proteome.faa
```

The workflow appends the supplied host FASTA during final database assembly and deduplicates it together with microbial protein sequences.

## Outputs

A typical completed build produces:

- a final protein FASTA database
- a manifest describing included genera
- a build plan table
- a Snakemake configuration file
- QC summary outputs
- provenance outputs

## Post-build QC summary

After the build completes, a QC summary can be generated in R:

```r
qc <- summarize_database_build(
  build_plan = "results/database_builds/saliva/saliva_build_plan.tsv",
  final_database = "results/database_builds/saliva/MetaproDB_saliva.faa"
)

qc$summary
```

QC report files can also be written to disk:

```r
write_build_qc_report(
  qc_report = qc,
  output_dir = "results/database_builds/saliva/qc",
  prefix = "saliva"
)
```

This writes files such as:

- `saliva.summary.tsv`
- `saliva.genus_status.tsv`
- `saliva.missing_genera.txt`

## Provenance output

MetaproDB also supports provenance reporting for completed builds.

```r
write_build_provenance(
  build_plan = "results/database_builds/saliva/saliva_build_plan.tsv",
  output_dir = "results/database_builds/saliva/provenance",
  prefix = "saliva"
)
```

This writes provenance files describing the planned build inputs and database construction context.

## Workflow summary

At a high level, the MetaproDB workflow is:

1. choose a bundled biome or provide a `phyloseq` object
2. rank and select genera in R
3. generate a genus manifest and build plan
4. write a Snakemake configuration file
5. run Snakemake to construct the database
6. inspect final outputs, QC summaries, and provenance files

## Notes

- The examples above assume use of the bundled genome resource archives under `resources/genomes/`.
- When working with bundled curated biomes, the genus index is read from `resources/genus_index.tsv`.
- The examples in this README are repository-oriented and assume access to bundled resource files included in the source checkout.
- For custom workflows, users are responsible for providing appropriate input data and for ensuring that required external tools are available in the active conda environment.
