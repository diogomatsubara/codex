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

	git clone git@github.com:starkandwayne/codex.git
	cd codex
	direnv allow .
	pip install -r requirements.txt

4. Run the ``sphinx-autobuild`` command and it will watch for changes and create a local server of the build folder.

::

	sphinx-autobuild docs build/html

5. Open the link provided by ``sphinx-autobuild`` for the local codex at http://127.0.0.1:8000.

.. _direnv: https://direnv.net

.. image:: docs/images/codex-local-setup.gif

About
-----

+------------------+-----------------------------------------------------+
| Name             | Purpose                                             |
+==================+=====================================================+
| archive/         | **codex-v1** source files                           |
+------------------+-----------------------------------------------------+
| build/           | **sphinx-doc** local only, use ``make`` for outputs |
+------------------+-----------------------------------------------------+
| docs/            | **sphinx-doc** source files                         |
+------------------+-----------------------------------------------------+
| terraform/       | **terraform** provisioning scripts                  |
+------------------+-----------------------------------------------------+
| .cfignore        | **cf** optimize deployment parameters               |
+------------------+-----------------------------------------------------+
| .envrc           | **direnv** builds a python virtual env              |
+------------------+-----------------------------------------------------+
| .gitignore       | **git** defines files to ignore in repo             |
+------------------+-----------------------------------------------------+
| Makefile         | **sphinx-doc** builds ``docs`` source               |
+------------------+-----------------------------------------------------+
| README.rst       | this file                                           |
+------------------+-----------------------------------------------------+
| Staticfile       | **cf** defines project as Staticfile app            |
+------------------+-----------------------------------------------------+
| manifest.yml     | **cf** configures app runtime parameters            |
+------------------+-----------------------------------------------------+
| requirements.txt | **python** dependencies for project                 |
+------------------+-----------------------------------------------------+

Codex uses sphinx-doc_, the python documentation generator, to build the
website into a static output of HTML webpages.  Then when the application is
deployed it, it copies the static output to a Cloud Foundry droplet and starts
an application instance.

.. _sphinx-doc: http://www.sphinx-doc.org/en/stable/index.html

Deploy
------

The Makefile at the root of this project has a *deploy* Makefile target.

When calling this target with ``make deploy`` it will use the ``sphinx`` python
module and the ``cf-cli`` commands to build and push the a sphinx-doc website.

1. Login to Cloud Foundry, target the **starkandwayne** organization, with
the **codex** space.

::

	cf login -a https://api.run.pivotal.io -o starkandwayne -s codex

2. To deploy codex, in the root of the project run:

::

	make deploy
