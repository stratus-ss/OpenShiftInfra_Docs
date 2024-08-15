This repo contains various explainations of OpenShift components and is meant to be composable so that various markdown files can be reused in the future.

This repo puts the source md files in src/. there is a helper shell script `make_docs.sh` which defines a table of contents and then creates a temporary directory. Once those are created, a symlink is created from the src/ directory to the tmp/ directory where the files are processed by [stitchmd](https://github.com/abhinav/stitchmd) and then outputted to the rendered/ directory
