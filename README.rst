codex
=====

Read
----

http://www.starkandwayne.com/codex

Write
-----

1. Install direnv_.

2. Install virtualenv python package: ``pip install virtualenv``.

3. Run these steps in order to get the source, setup a ``virtualenv``, and install python module dependencies.

::

	git clone https://github.com/starkandwayne/codex.git
	cd codex
	direnv allow .
	pip install -r requirements.txt

4. Run the ``sphinx-autobuild`` command and it will watch for changes and create a local server of the build folder.

::

	sphinx-autobuild docs build/html

5. Open the link provided by ``sphinx-autobuild`` for the local codex_.

.. _direnv: https://direnv.net
.. _codex:  http://127.0.0.1:8000

.. image:: docs/images/codex-local-setup.gif

About
-----

+------------------+----------------------------------------------+
| Name             | Purpose                                      |
+==================+==============================================+
| archive/         | **codex-v1** source files                    |
+------------------+----------------------------------------------+
| docs/            | **sphinx-doc** source files                  |
+------------------+----------------------------------------------+
| terraform/       | **terraform** provisioning scripts           |
+------------------+----------------------------------------------+
| .cfignore        | **cf** optimize deployment parameters        |
+------------------+----------------------------------------------+
| .envrc           | **direnv** builds a python virtual env       |
+------------------+----------------------------------------------+
| .gitignore       | **git** defines files to ignore in repo      |
+------------------+----------------------------------------------+
| Makefile         | **sphinx-doc** builds ``docs`` source        |
+------------------+----------------------------------------------+
| README.rst       | this file                                    |
+------------------+----------------------------------------------+
| Staticfile       | **cf** defines project as Staticfile app     |
+------------------+----------------------------------------------+
| manifest.yml     | **cf** configures app runtime parameters     |
+------------------+----------------------------------------------+
| requirements.txt | **python** dependencies for project          |
+------------------+----------------------------------------------+

Codex uses sphinx-doc_, the python documentation generator, to build the
website into a static output of HTML webpages.  Then when the application is
deployed it, it copies the static output to a Cloud Foundry droplet and starts
an application instance.

.. _sphinx-doc: http://www.sphinx-doc.org/en/stable/index.html
