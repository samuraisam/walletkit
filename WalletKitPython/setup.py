import os
import itertools
import platform
from os import path
from pathlib import Path
from setuptools import setup, Extension
from Cython.Build import cythonize

LIBRARIES = ["resolv"]

if platform.system() == 'Darwin':
    os.environ['LDFLAGS'] = '-framework Security'
if platform.system() == 'Linux':
    LIBRARIES += ["bsd", "sqlite3"]

HERE = path.dirname(path.abspath(__file__))
CORE_ROOT = path.abspath(path.join(HERE, path.pardir, 'WalletKitCore'))
CORE_SRC_FILES = list(map(str, itertools.chain(
    Path(path.join(CORE_ROOT, 'src')).rglob('*.c'),
    Path(path.join(CORE_ROOT, 'vendor', 'ed25519')).rglob('*.c')
)))
CORE_COMPILE_ARGS = [
    "-Wall",
    "-Wconversion",
    "-Wsign-conversion",
    "-Wparentheses",
    "-Wswitch",
    "-Wno-implicit-int-conversion",
    "-Wno-missing-braces",
]
CYTHON_FILES = list(map(str, Path(path.join(HERE, 'walletkit')).glob('*.pyx')))
CYTHON_INCLUDE_DIRS = [path.join(HERE, 'walletkit')]
INCLUDE_DIRS = [
    path.join(CORE_ROOT, 'src'),
    path.join(CORE_ROOT, 'include'),
    path.join(CORE_ROOT, 'vendor'),
    path.join(CORE_ROOT, 'vendor', 'secp256k1'),
]

setup(
    name='walletkit',
    version='0.1.0',
    author="Samuel Sutch",
    author_email="sam@blockset.com",
    description="A wrapper around the WalletKit library",
    license="MIT",
    url="https://github.com/blockset-corp/walletkit",
    packages=['walletkit', 'walletkit.wordlists'],
    setup_requires=[
        'setuptools>=41.6.0',
        'Cython>=0.29.14',
    ],
    ext_package='walletkit',
    ext_modules=cythonize([
        Extension(
            'native', CYTHON_FILES,
            include_dirs=INCLUDE_DIRS,
            libraries=["walletkitcore"] + LIBRARIES
        )],
        include_path=CYTHON_INCLUDE_DIRS,
        language_level=3
    ),
    libraries=[
        ['walletkitcore', {
            'sources': CORE_SRC_FILES,
            'include_dirs': INCLUDE_DIRS,
            'libraries': LIBRARIES,
            'extra_compile_args': CORE_COMPILE_ARGS
        }]
    ],
    zip_safe=False
)
