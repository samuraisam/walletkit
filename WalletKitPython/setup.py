import os
import itertools
import platform
from os import path
from pathlib import Path
from setuptools import Extension
from distutils.core import setup
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
CYTHON_INCLUDE_DIRS = [path.join(HERE, 'walletkit')]
INCLUDE_DIRS = [
    path.join(CORE_ROOT, 'src'),
    path.join(CORE_ROOT, 'include'),
    path.join(CORE_ROOT, 'vendor'),
    path.join(CORE_ROOT, 'vendor', 'secp256k1'),
]
EXTENSIONS = [Extension(
    'native', [path.join(HERE, 'walletkit', 'native.pyx')] + CORE_SRC_FILES,
    include_dirs=INCLUDE_DIRS,
    libraries=LIBRARIES,
    extra_compile_args=[
        "-Wall",
        "-Wconversion",
        "-Wsign-conversion",
        "-Wparentheses",
        "-Wswitch",
        "-Wno-implicit-int-conversion",
        "-Wno-missing-braces",
    ]
)]

setup(
    name='walletkit',
    version='0.1.0',
    author="Samuel Sutch",
    author_email="sam@blockset.com",
    description="A wrapper around the WalletKit library",
    license="MIT",
    url="https://github.com/blockset-corp/walletkit",
    packages=['walletkit'],
    ext_package='walletkit',
    ext_modules=cythonize(
        EXTENSIONS,
        include_path=CYTHON_INCLUDE_DIRS,
        language_level=3
    ),
    zip_safe=False
)
