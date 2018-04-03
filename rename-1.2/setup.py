#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright (C) 2010 Łukasz Langa
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
import sys
from setuptools import setup, find_packages

reload(sys)
sys.setdefaultencoding('utf8')

ld_file = open(os.path.join(os.path.dirname(__file__), 'README.rst'))
try:
    long_description = ld_file.read()
finally:
    ld_file.close()
# We let it die a horrible tracebacking death if reading the file fails.
# We couldn't sensibly recover anyway: we need the long description.

setup (
    name = 'rename',
    version = '1.2',
    author = 'Łukasz Langa',
    author_email = 'lukasz@langa.pl',
    description = "Renames files using regular expressions",
    long_description = long_description,
    url = 'https://bitbucket.org/langacore/rename',
    keywords = '',
    platforms = ['any'],
    license = 'GPL v3',
    py_modules = ['rename'],
    package_dir = {'': 'src'},
    include_package_data = True,
    scripts = ['bin/rename'],
    zip_safe = False, # if only because of the readme file
    install_requires = [
        'argparse',
        ],

    classifiers = [
        'Development Status :: 5 - Production/Stable',
        'License :: OSI Approved :: GNU General Public License (GPL)',
        'Natural Language :: English',
        'Operating System :: POSIX',
        'Programming Language :: Python',
        'Topic :: Software Development :: Libraries :: Python Modules',
        ]
    )
