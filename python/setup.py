"""
Setup script for Reia Python package.

Converted from Rust to Python 3.14
"""

from setuptools import setup, find_packages

setup(
    name="reia",
    version="0.1.0",
    description="Reia - Open-source RPG/MMO game engine extension",
    author="Reia Contributors",
    author_email="",
    url="https://github.com/eightynine01/Reia",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    python_requires=">=3.14",
    install_requires=[
        # Add runtime dependencies here
        # "godot-python>=0.9.0",
        # "libsql-client>=0.1.0",
    ],
    extras_require={
        "dev": [
            "pytest>=8.0.0",
            "pytest-asyncio>=0.23.0",
            "mypy>=1.8.0",
            "black>=24.0.0",
            "ruff>=0.1.0",
        ],
    },
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Topic :: Games/Entertainment",
        "Programming Language :: Python :: 3.14",
        "License :: OSI Approved :: MIT License",
    ],
)
