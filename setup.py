#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# devwraps - some device wrappers for Python
# Copyright 2018 J. Antonello <jacopo.antonello@dpag.ox.ac.uk>
#
# This file is part of devwraps.
#
# devwraps is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# devwraps is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with devwraps.  If not, see <http://www.gnu.org/licenses/>.

# https://github.com/cython/cython/wiki/CythonExtensionsOnWindows
# https://matthew-brett.github.io/pydagogue/python_msvc.html
# http://landinghub.visualstudio.com/visual-cpp-build-tools

# To compile install MSVC 2015 command line tools and run
# python setup.py build_ext --inplace


import os
import numpy
import re

from os import path
from shutil import copyfile
from setuptools import setup
from setuptools.extension import Extension
from Cython.Build import cythonize


here = path.abspath(path.dirname(__file__))
with open(path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

PROGFILES = os.environ['PROGRAMFILES']


def lookup_version():
    with open(os.path.join('devwraps', '__init__.py'), 'r') as f:
        m = re.search(r"^__version__ = ['\"]([^'\"]*)['\"]", f.read(), re.M)
    return m.group(1)


def make_ciusb(fillout, remove, pkgdata):
    dir1 = path.join(PROGFILES, r'Boston Micromachines\Usb\CIUsbLib')
    f1 = path.join(
        PROGFILES,
        r'Boston Micromachines\Usb\Examples\UsbExMulti\_CIUsbLib.tlb')
    dst = path.join(r'devwraps', '_CIUsbLib.tlb')

    if not path.isdir(dir1):
        return

    copyfile(f1, dst)
    fillout.append(Extension(
        'devwraps.ciusb', [r'devwraps\ciusb.pyx', r'devwraps\cciusb.cpp'],
        include_dirs=[r'ciusb', numpy.get_include(), dir1],
        library_dirs=[dir1],
        libraries=['CIUsbLib'],
        language='c++',
    ))
    remove.append(dst)
    remove.append(r'devwraps\ciusb.cpp')


def make_bmc(fillout, remove, pkgdata):
    dir1 = path.join(PROGFILES, r'Boston Micromachines\Lib64')
    dir2 = path.join(PROGFILES, r'Boston Micromachines\Include')

    if not path.isdir(dir1) or not path.isdir(dir2):
        return

    fillout.append(Extension(
        'devwraps.bmc', [r'devwraps\bmc.pyx'],
        include_dirs=[r'devwraps', numpy.get_include(), dir2],
        library_dirs=[dir1],
        libraries=['BMC2'],
    ))
    remove.append(r'devwraps\bmc.c')


def make_thorcam(fillout, remove, pkgdata):
    p1 = r'Thorlabs\Scientific Imaging\DCx Camera Support\Develop'
    p2 = r'Thorlabs\Scientific Imaging\ThorCam\uc480_64.dll'
    dir1 = path.join(PROGFILES, p1, r'Include')
    dir2 = path.join(PROGFILES, p1, r'Lib')
    pristine = path.join(dir1, 'uc480.h')
    patched = path.join(r'devwraps', 'uc480.h')

    if not path.isdir(dir1) or not path.isdir(dir2):
        return

    with open(pristine, 'r') as f:
        incl = f.read()
    incl = re.sub(r'#define IS_SENSOR_C1280G12M *0x021E', '', incl, 1)
    incl = re.sub(r'#define IS_SENSOR_C1280G12C *0x021F', '', incl, 1)
    incl = re.sub(r'#define IS_SENSOR_C1280G12N *0x0220', '', incl, 1)
    incl = re.sub(r'extern "C" __declspec', r'extern __declspec', incl, 2)
    with open(patched, 'w') as f:
        f.write(incl)

    fillout.append(Extension(
        'devwraps.thorcam', [r'devwraps\thorcam.pyx'],
        include_dirs=[r'devwraps', numpy.get_include()],
        library_dirs=[dir2],
        libraries=['uc480_64'],
    ))
    remove.append(patched)
    remove.append(r'devwraps\thorcam.c')
    pkgdata.append((r'lib\site-packages\devwraps', [path.join(PROGFILES, p2)]))


def make_sdk3(fillout, remove, pkgdata):
    dir1 = path.join(PROGFILES, r'Andor SDK3')

    if not path.isdir(dir1):
        return

    fillout.append(Extension(
        'devwraps.sdk3', [r'devwraps\sdk3.pyx'],
        include_dirs=[r'devwraps', numpy.get_include(), dir1],
        library_dirs=[dir1],
        libraries=['atcorem'],
    ))
    remove.append(r'devwraps\sdk3.c')


exts = []
remove = []
pkgdata = []
make_ciusb(exts, remove, pkgdata)
make_bmc(exts, remove, pkgdata)
make_thorcam(exts, remove, pkgdata)
make_sdk3(exts, remove, pkgdata)
names = [e.name for e in exts]
if len(names) == 0:
    raise ValueError('No drivers found')


setup(
    name='devwraps',
    version=lookup_version(),
    description='Python wrappers for deformable mirrors and cameras',
    long_description=long_description,
    url='',
    author='Jacopo Antonello',
    author_email='jacopo.antonello@dpag.ox.ac.uk',
    license='GPLv3+',
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Topic :: Scientific/Engineering :: Physics', (
            'License :: OSI Approved :: GNU General Public License v3 ' +
            'or later (GPLv3+)'),
        'Programming Language :: Python :: 3',
        'Operating System :: Microsoft :: Windows'
    ],
    packages=['devwraps'],
    ext_modules=cythonize(exts, compiler_directives={'language_level': 3}),
    install_requires=['numpy', 'cython'],
    zip_safe=False,
    data_files=pkgdata)

try:
    for f in remove:
        os.remove(f)
except OSError:
    pass

print('installed extensions are {}'.format(', '.join(names)))
