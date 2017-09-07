codex-v2
========

Uses sphinx-doc_, the python documentation generator, to build the codex_ website.

.. _sphinx-doc: http://www.sphinx-doc.org/en/stable/index.html
.. _codex:      http://www.starkandwayne.com/codex

+------------------+----------------------------------------------+
| Name             | Purpose                                      |
+==================+==============================================+
| docs/            | documentation source files                   |
+------------------+----------------------------------------------+
| terraform/       | files to run terraform provisioning          |
+------------------+----------------------------------------------+
| .envrc           | starts a python virtual env with ``direnv``  |
+------------------+----------------------------------------------+
| .gitignore       | globally controls files ignored by git repo  |
+------------------+----------------------------------------------+
| Makefile         | sphinx Makefile, builds from ``docs`` source |
+------------------+----------------------------------------------+
| README.rst       | this file                                    |
+------------------+----------------------------------------------+
| requirements.txt | records python dependencies for project      |
+------------------+----------------------------------------------+
