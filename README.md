## Installation
Refer to the pre-commit install documentation [link](https://github.com/antonbabenko/pre-commit-terraform/blob/master/README.md#1-install-dependencies)

## Usage
The terraform code needs to exist in a git initialized repository.
Create a .pre-commit-config.yaml file on the root of the repository and add the config. 

## Sample config
```
repos:
  - repo: https://github.com/Imperial-ICT-Cloud-TerraformRegistry/git-hooks
    rev: 0.0.1 # Check for latest revision from [releases] (https://github.com/Imperial-ICT-Cloud-TerraformRegistry/git-hooks/releases)
    hooks:
      - id: add-readme # Id of the git hook
```
