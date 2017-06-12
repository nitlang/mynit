# NAME

nitmetrics -- computes various metrics on Nit programs.

# SYNOPSIS

nitmetrics [*options*]... FILE...

# OPTIONS

## METRICS

### `--all`
Compute all metrics.

### `--model`
Compute metrics about the model.

### `--mpackages`
Compute metrics about mpackages.

### `--mmodules`
Compute metrics about mmodules.

### `--mclasses`
Compute metrics about mclasses.

### `--mendel`
Compute mendel metrics.

### `--inheritance`
Compute metrics about inheritance usage.

### `--refinement`
Compute metrics about refinement usage.

### `--doc`
Compute metrics about documentation.

### `--self`
Compute metrics about the usage of explicit and implicit self.

### `--ast`
Compute metrics about the usage of nodes and identifiers in the AST.

### `--nullables`
Compute metrics on nullables send.

### `--static-types`
Compute explicit static types metrics.

### `--tables`
Compute tables metrics.

### `--rta`
Compute RTA metrics.

### `--generate_hyperdoc`
Generate Hyperdoc.

### `--poset`
Complete metrics on posets.

### `--detect-variance-constraints`
Detect the definition-site variance constraints on formal parameters.

Infers the possible variance annotations of formal types in Nit programs by identifying the existing constraints on the usage of those formal type.

### `--detect-covariance`
Detect the static covariance usages.

## OUTPUT

### `--csv`
Also export metrics in CSV format.

### `-d`, `--dir`
Directory where some statistics files are generated.

### `--no-colors`
Disable colors in console outputs.

# SEE ALSO

The Nit language documentation and the source code of its tools and libraries may be downloaded from <http://nitlanguage.org>
