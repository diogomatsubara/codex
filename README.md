codex
=====

Read
----

http://www.starkandwayne.com/codex

Write
-----

1. Install docker_.

2. Clone the codex repository locally::

	git clone git@github.com:starkandwayne/codex.git && cd codex

3. Build and run the docker container with the latest source::

	make docker

( Note that you can also run ``make build`` to only build or ``make run`` to directly run a previous built codex image )

4. Open codex at http://127.0.0.1:8000 in your browser. Note that changes that are made locally will be reflected in the browser upon refresh.

.. _docker: https://www.docker.com/

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
