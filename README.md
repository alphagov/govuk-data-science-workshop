# `govuk-data-science-workshop`

Materials for a workshop about data science and GOV.UK.  To run the notebook in
your browser, click the button below that is labelled "launch binder".

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/alphagov/govuk-data-science-workshop/requirements?filepath=notebooks%2F2021_09_explore_govuk_structural_network.ipynb)
```{warning}
Where this documentation refers to the root folder we mean where this README.md is
located.
```

## Getting started

To start using this project, [first make sure your system meets its
requirements](#requirements).

To be added.

### Requirements

```{note} Requirements for contributors
[Contributors have some additional requirements][contributing]!
```

- Python 3.6.1+ installed

To install the Python requirements, open your terminal and enter:

```shell
pip install -r requirements.txt
```

## Data

A dataset of the GOV.UK website structural network adjacency list (how pages
link to each other) is included in the file
`data/raw/structural_network_adjacency_list_20190301.csv`.  It was originally
obtained from
[GOV.UK](https://data.gov.uk/dataset/00f43927-0c93-4f9e-9632-b082fdbb0299/gov-uk-structural-network-adjacency-list).

## Licence

Unless stated otherwise, the codebase is released under the MIT License. This covers
both the codebase and any sample code in the documentation. The documentation is ©
Crown copyright and available under the terms of the Open Government 3.0 licence.

## Contributing

[If you want to help us build, and improve `govuk-data-science-workshop`, view our
contributing guidelines][contributing].

## Acknowledgements

[This project structure is based on the `govcookiecutter` template
project][govcookiecutter].

[contributing]: ./docs/contributor_guide/CONTRIBUTING.md
[govcookiecutter]: https://github.com/best-practice-and-impact/govcookiecutter
[docs-loading-environment-variables]: ./docs/user_guide/loading_environment_variables.md
[docs-loading-environment-variables-secrets]: ./docs/user_guide/loading_environment_variables.md#storing-secrets-and-credentials
