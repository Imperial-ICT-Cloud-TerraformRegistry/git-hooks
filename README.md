## Installation
Refer to the pre-commit install documentation [link](https://github.com/antonbabenko/pre-commit-terraform/blob/master/README.md#1-install-dependencies)

## Usage
The terraform code needs to exist in a git initialized repository.
Create a .pre-commit-config.yaml file on the root of the repository and add the config. 

## Sample config
```
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.98.0 # Get the latest from: https://github.com/antonbabenko/pre-commit-terraform/releases
    hooks:
      - id: terraform_fmt
      - id: terraform_docs
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0 # Use the ref you want to point at
    hooks:
      - id: trailing-whitespace
  - repo: https://github.com/Imperial-ICT-Cloud-TerraformRegistry/git-hooks
    rev: 0.0.1 # Get the latest from: https://github.com/Imperial-ICT-Cloud-TerraformRegistry/git-hooks/releases
    hooks:
      - id: add-readme

```
