Some Title Here
===============

A Slide - Cool
--------------

Intro or something.


Example Code (python)
---------------------

.. sourcecode:: python

    >>> from rtree import Rtree
    >>> r = Rtree() # in memory
    >>> for i in range(1000):
    ...    r.add(i, (i, i, i + 2, i + 2))

    >>> r.intersection((0, 0, 2, 2))
    [0L, 1L, 2L]


Example Code (bash) 
-------------------
 
.. sourcecode:: bash

    NAME=index
    python rst-directive.py \
        --stylesheet=pygments.css \
        --theme-url=ui/small-black \
        ${NAME}.rst > ${NAME}.html

Source
------

get the code from:

.. sourcecode:: bash

    svn checkout http://bpgeo.googlecode.com/svn/trunk/rst2s5_template/

.. footer:: svn checkout http://bpgeo.googlecode.com/svn/trunk/rst2s5_template/

