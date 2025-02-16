from setuptools import find_packages, setup

setup(
    name="graph-computation",
    version="0.1.0",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    install_requires=[
        "flask>=2.0.0",
        "flask-cors>=4.0.0",
        "pandas>=1.5.0",
        "networkx>=3.0",
        "python-dateutil>=2.8.2",
        "pyodbc>=4.0.35",
        "pydantic>=2.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "black>=22.0.0",
            "pylint>=2.14.0",
        ],
    },
    python_requires=">=3.9",
    author="Your Name",
    author_email="your.email@example.com",
    description="A library for processing and analyzing weighted trees across time snapshots",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    keywords="graph, tree, analysis, weights, time-series",
    url="https://github.com/yourusername/graph-computation",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3.9",
    ],
) 