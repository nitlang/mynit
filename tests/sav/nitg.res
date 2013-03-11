  -W, --warn                  Show warnings
  -q, --quiet                 Do not show warnings
  --stop-on-first-error       Stop on first error
  --no-color                  Do not use color to display errors and warnings
  --log                       Generate various log files
  --log-dir                   Directory where to generate log files
  -h, -?, --help              Show Help (This screen)
  --version                   Show version and exit
  -v, --verbose               Verbose
  -I, --path                  Set include path for loaders (may be used more than once)
  --only-parse                Only proceed to parse step of loaders
  --only-metamodel            Stop after meta-model processing
  -o, --output                Output file
  --no-cc                     Do not invoke C compiler
  --make-flags                Additional options to make
  --hardening                 Generate contracts in the C code against bugs in the compiler
  --no-shortcut-range         Always insantiate a range and its iterator on 'for' loops
  --no-check-covariance       Disable type tests of covariant parameters (dangerous)
  --no-check-initialization   Disable isset tests at the end of constructors (dangerous)
  --no-check-assert           Disable the evaluation of explicit 'assert' and 'as' (dangerous)
  --no-check-autocast         Disable implicit casts on unsafe expression usage (dangerous)
  --no-check-other            Disable implicit tests: unset attribute, null receiver (dangerous)
  --typing-test-metrics       Enable static and dynamic count of all type tests
  --separate                  Use separate compilation
  --no-inline-intern          Do not inline call to intern methods
  --no-union-attribute        Put primitive attibutes in a box instead of an union
  --no-shortcut-equal         Always call == in a polymorphic way
  --inline-coloring-numbers   Inline colors and ids
  --tables-metrics            Enable static size measuring of tables used for vft, typing and resolution
  --bm-all-tables             Replace coloring by binary matrix for all tables
  --phmod-all-tables          Replace coloring by perfect hashing for all tables (with mod operator)
  --phand-all-tables          Replace coloring by perfect hashing for all tables (with and operator)
  --bm-typing                 Replace typing tables coloring by binary matrix
  --phmod-typing              Replace typing tables coloring by perfect hashing (with mod operator)
  --phand-typing              Replace typing tables coloring by perfect hashing (with and operator)
  --bm-resolution             Replace resolution tables coloring by binary matrix
  --phmod-resolution          Replace resolution tables coloring by perfect hashing (with mod operator)
  --phand-resolution          Replace resolution tables coloring by perfect hashing (with and operator)
  --bm-vft                    Replace vft coloring by binary matrix
  --phmod-vft                 Replace vft coloring by perfect hashing (with mod operator)
  --phand-vft                 Replace vft coloring by perfect hashing (with and operator)
  --bm-attrs                  Replace attributes tables coloring by binary matrix
  --phmod-attrs               Replace attributes tables coloring by perfect hashing (with mod operator)
  --phand-attrs               Replace attributes tables coloring by perfect hashing (with and operator)
  --erasure                   Erase generic types
  --no-check-erasure-cast     Disable implicit casts on unsafe return with erasure-typing policy (dangerous)
