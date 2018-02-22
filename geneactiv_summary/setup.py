from setuptools import setup, find_packages

setup(name="geneactiv_summary",
      description="Summary values (6 hr epoc) for geneactiv data",
      author="Neuroinformatics Research Group",
      author_email="support@neuroinfo.org",
      packages=find_packages(),
      scripts=['geneactiv_summary.py'],
      url="http://neuroinformatics.harvard.edu/",
      install_requires=[
        "importlib",
        "argparse",
        "logging",
        "collections",
        "pandas",
        "datetime",
        "dateutil",
        "csv",
        "math"
    ]
)
