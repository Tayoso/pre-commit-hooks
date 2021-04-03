[TOC]

# What are Git Hooks?

Git hooks are shell scripts that run automatically before or after git executes an important command like Commit or Push. You can find hooks in your **.git** folder. When you `$ git init`, that command generates a number of hooks which define how git is able to write from your local to your remote repository. 

<img src="..\images\git-hooks.png" alt="git-hooks" style="zoom:50%;" />

A description of some of the hooks above are highlighted in the table below [1]. Depending on your software requirements and your knowledge of Bash, you can harness the full potential of these hooks and also create custom hooks. For more info, read this article on creating custom pre-commit hooks [Implement your own Pre-commit Hooks](https://towardsdatascience.com/how-to-code-your-own-python-pre-commit-hooks-with-bash-171298c6ee05).

| Git Hook                  | Git command | Usage                                                    |
| ------------------------- | ----------- | -------------------------------------------------------- |
| post-update.sample        | git push    | By updating all data after the push                      |
| commit-msg.sample         | git commit  | To set the message of a commit action                    |
| pre-commit.sample         | git commit  | Before committing                                        |
| prepare-commit-msg.sample | git commit  | When a commit message is set                             |
| pre-push.sample           | git push    | Before making a push                                     |
| pre-receive.sample        | git push    | When we push and get the data from the remote repository |
| update.sample             | git push    | By updating the remote data in a push                    |



# Pre-Commit Hooks

Pre-commit hooks are a mechanism of the version control system git. They let you execute code right before the commit. In this wiki, we will highlight a few packages which are useful for static code analysis. Some of which are the very hooks used in the pre-commit hooks.[2]

<img src="..\images\pre_com_image.jpeg" style="zoom:50%;" />



Create a `.pre-commit-config.yaml` file within your project and use in multiple projects. This file contains the pre-commit hooks you want to run every time before you commit. It looks like this [3]

```yaml
# All available hooks: https://pre-commit.com/hooks.html
# This is for python
repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v3.2.0
    hooks:
    -   id: trailing-whitespace
    -   id: mixed-line-ending
-   repo: https://github.com/psf/black
    rev: 20.8b1
    hooks:
    -   id: black
```



```yaml
# All available hooks: https://pre-commit.com/hooks.html
# R specific hooks: https://github.com/lorenzwalthert/precommit
repos:
-   repo: https://github.com/lorenzwalthert/precommit
    rev: v0.1.3
    hooks: 
    -   id: style-files
        args: [--style_pkg=styler, --style_fun=tidyverse_style]    
    -   id: spell-check
    -   id: lintr
    -   id: readme-rmd-rendered
    -   id: parsable-R
    -   id: no-browser-statement
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v3.4.0
    hooks: 
    -   id: check-added-large-files
        args: ['--maxkb=200']
    -   id: end-of-file-fixer
        exclude: '\.Rd'
-   repo: local
    hooks:
    -   id: forbid-to-commit
        name: Don't commit common R artifacts
        entry: Cannot commit .Rhistory, .RData, .Rds or .rds.
        language: fail
        files: '\.Rhistory|\.RData|\.Rds|\.rds$'
        # `exclude: <regex>` to allow committing specific files.

```



## Why use Pre-commit hooks?

- Improve the quality of commits, obviously.
- Very useful in production environments for code compliance.
- These hooks help **automate static code analysis** thereby informing the developer of potential issues within the code.



### Type of hooks

Some hooks are specific to programming languages other than Python and R. However, most of these hooks can be used in generic projects to check other non-specific programming scripts.

- Code autoformatting
  - R: lintr
  - Python: pylint
- Code quality and styling
  - R: styler, tidyverse_style
  - Python: black, flake8

- File formatting
  - check-json
  - check-yaml
  - end-of-file-fixer
  - trailing-whitespace
- Security
- Miscellaneous
  - check-large-files



## Installation in R

```R
# install required packages 
install.packages("precommit")
install.packages("reticulate")
install.packages("git2r")

# install miniconda which will run the pre-commit
reticulate::install_miniconda()

# install the pre-commit framework in the conda environment
precommit::install_precommit()

# IMPORTANT: in a fresh R session
# this automatically generates your precommit yaml file
precommit::use_precommit()

```

```bash
# Using git bash, add the files before running the commit as you would normally
git add .

# test it works by running against added files
git commit

# to ignore pre-commit and commit-msg hooks
git commit -n
```

For full set up guide see in link [Install and use pre-commit hooks in R](https://cran.r-project.org/web/packages/precommit/readme/README.html). 



## Python

```bash
# install required packages 
pip install pre-commit

# In a python project, add the following to your requirements.txt 
pre-commit

# check if pre-commit is installed by querying the version in use
pre-commit --version

# NEXT STEPS: 
# Add pre-commit config by creating a file named using the python .pre-commit-config.yaml example above 
# install the githook scripts
pre-commit install

# add the files before running the commit as you would normally
git add .

# test it works by running against added files
pre-commit run --all-files

# to ignore pre-commit and commit-msg hooks
git commit -n
```

For full set up guide see in link [Install and use pre-commit hooks in python](https://pre-commit.com). 



## Sources

1. [What are Git Hooks and How to Start Using Them? (hostinger.co.uk)](https://www.hostinger.co.uk/tutorials/how-to-use-git-hooks/#:~:text=Git hooks are shell scripts,we can automate certain things.)
2. https://towardsdatascience.com/static-code-analysis-for-python-bdce10b8d287
3. [Pre-commit hooks you must know. Boost your productivity and code… | by Martin Thoma | Towards Data Science](https://towardsdatascience.com/pre-commit-hooks-you-must-know-ff247f5feb7e)# pre-commit-hooks
