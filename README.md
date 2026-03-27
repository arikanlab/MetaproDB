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
- evaluating build completeness using configurable recovery thresholds

## Main features

- Bundled curated biome resources for database planning
- Support for user-provided `phyloseq` objects
- Taxon selection using **top-N abundance** and optional **core taxa** inclusion
- Genome manifest generation for selected genera
- Snakemake-based execution workflow
- Optional host proteome merging
- Post-build QC summaries
- Provenance reporting for reproducibility
- Threshold-based handling of partial genome recovery during workflow execution

## Installation

MetaproDB has two coordinated components:

- an **R package** for planning database builds
- a **Snakemake workflow** for genome download, rehydration, protein extraction, and database assembly

The recommended setup is:

1. clone the repository
2. create and activate the workflow conda environment
3. install the R package from the repository
4. verify the required tools
5. run the smoke test

### 1. Clone the repository

```bash
git clone https://github.com/arikanlab/MetaproDB.git
cd MetaproDB
```

### 2. Create and activate the conda environment

Create the environment used for the Snakemake workflow and command-line tools:

```bash
conda env create -f workflow/envs/metaprodb.yml
conda activate metaprodb
```

This environment provides the main workflow dependencies, including:

- `snakemake`
- `ncbi-datasets-cli`
- `seqkit`

For more reliable dependency resolution, it is recommended to enable strict channel priority:

```bash
conda config --set channel_priority strict
```

### 3. Install the R package

With the `metaprodb` conda environment still activated, start R from the repository root and install the package:

```r
install.packages("devtools")
devtools::install(".")
```

This installs the MetaproDB R package together with the R dependencies listed in `DESCRIPTION`.

### 4. Verify the installation

From the activated conda environment, confirm that the required workflow tools are available:

```bash
which snakemake
which datasets
which seqkit
```

You can also check tool versions:

```bash
datasets --version
seqkit version
```

Then confirm that the R package loads:

```r
library(metaprodb)
```

### 5. Run the workflow smoke test

After installation, run:

```bash
bash tests/workflow/smoke_test.sh
```

This smoke test is fully local and does not depend on live NCBI rehydration.

## Inputs

MetaproDB can be used with either of the following input types:

### 1. Bundled curated biome resources

MetaproDB includes bundled biome objects together with metadata describing the curated biome panel. These resources can be used directly for taxon selection and database planning.


The bundled biome set currently includes the following curated resources. Use the `biome_id` values below with `plan_build_from_biome()`.

| biome_id | Samples (n) |
|---|---:|
| blood | 226 |
| buccal_mucosa | 287 |
| dairy_products | 862 |
| drinking_water | 158 |
| fermented_beverages | 120 |
| fermented_vegetables | 289 |
| forest_soil | 1368 |
| hydrothermal_vents | 113 |
| nasal_cavity | 1603 |
| pharynx | 526 |
| saliva | 4881 |
| sediment | 2420 |
| skin | 5920 |
| soil | 3445 |
| supragingival_plaque | 487 |
| thermal_springs | 663 |
| throat | 660 |
| tongue_dorsum | 473 |
| trachea | 238 |
| vagina | 4524 |


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
- `results/database_builds/saliva/build_completeness.tsv`

## Custom phyloseq workflow

Use a user-provided phyloseq object to build a database tailored to that dataset.

### Important note on `resource_dir`

For custom `phyloseq` workflows, set `resource_dir` to an **empty or dedicated directory** for that build. This avoids unintended reuse of previously cached genome archives and ensures that genome downloads for the current build are written to a user-controlled location.

### Step 1: plan the build in R

```r
library(metaprodb)

ps <- readRDS("my_phyloseq.rds")

res <- plan_build_from_phyloseq(
  ps = ps,
  biome_id = "my_microbiome",
  resource_dir = "results/database_builds/my_microbiome/genome_cache",
  top_n = 20,
  include_core = TRUE,
  prevalence = 0.5,
  abundance = 0.01,
  write_plan = TRUE
)
```

This creates a build plan and writes the workflow files needed to run database construction. The returned object `res` contains the selected taxa, build plan information, and paths to generated files.

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
- `results/database_builds/my_microbiome/build_completeness.tsv`

## Handling partial genome recovery

Genome download and rehydration can occasionally be incomplete because of remote resource availability. MetaproDB therefore supports threshold-based handling of partial recovery during workflow execution.

The generated Snakemake config includes:

- `download_failure_policy`
- `min_genome_success_fraction`
- `min_genus_success_fraction`

By default, custom builds are configured with a **permissive** policy and threshold values that allow the workflow to continue when recovery remains sufficiently complete. Build success is then evaluated using:

- the fraction of selected genera represented by at least one recovered protein FASTA
- the fraction of expected genomes successfully recovered

These summaries are written to:

- `build_completeness.tsv`

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
- a manifest describing included genera and assemblies
- a build plan table
- a Snakemake configuration file
- a build completeness summary
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
6. inspect final outputs, build completeness summaries, QC summaries, and provenance files

## Current scope and limitations

MetaproDB currently supports reproducible, biome-informed metaproteomic database construction from either bundled curated biome resources or user-provided phyloseq objects.

Current release scope:

- database planning is performed in R
- database construction is executed with the bundled Snakemake workflow
- taxon selection is based on top-N abundance with optional core taxa inclusion
- genome downloads for custom phyloseq workflows are written to a user-specified resource directory
- host proteome inclusion is supported only when a user-supplied host FASTA file is provided
- partial genome recovery can be handled under configurable completeness thresholds

MetaproDB does not currently:

- automatically download host proteomes
- claim universal superiority over alternative database construction strategies
- replace matched metagenome-based database construction where those data are available and appropriate

## Citation

If you use MetaproDB, please cite the GitHub repository/release. A manuscript citation will be added here after publication.

## Notes

- The bundled-biome examples above assume use of the tracked genome resource archives under `resources/genomes/`.
- For custom `phyloseq` workflows, use a dedicated `resource_dir` for the current build rather than a shared cache directory.
- The examples in this README are repository-oriented and assume access to bundled resource files included in the source checkout.
- For custom workflows, users are responsible for providing appropriate input data and for ensuring that required external tools are available in the active conda environment.
- Host proteomes must be supplied by the user if host sequence inclusion is desired.
