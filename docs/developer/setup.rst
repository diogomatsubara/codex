Developer
=========

Quick Start
-----------

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
