#!/usr/bin/env python

"""
DP REPORT GENERATOR FOR EMBRACE DATA
------------------------------------
Dependencies:
    pandas
    numpy
    jinja2
    weasyprint

Run:
  python3 report_gen.py {patientID}

The file requires:
  (1) DIA.csv:  contains metadata for all patients in the study
  (2) DIA_combined.png:  results generated from autogplot.sh
  (3) body_template.html:  HTML template for generating the HTML report

Please note what the report will be generated in the patient's study folder on the server.
The report is titled DIA_{metadata}_report.html.

Author:     Joshua D. Salvi
Year:       2018
"""

import pandas as pd
import numpy as np
from jinja2 import Environment, FileSystemLoader
# from weasyprint import HTML
import sys
import shutil
import os

def get_metadata(metadatafile, patientID):
    
    # Gather metadata information for a single subject ID to put into file
    df = pd.read_csv(metadatafile)
    patient_metadata = df.loc[df['SubjectID'] == patientID]

    return patient_metadata


def html_renderer(html_template, study, patient, consentdate, comments, actID, embID, actdata):

    # Use HTML template and replace all {{___}} with appropriate variables
    env = Environment(loader=FileSystemLoader('.'))
    template = env.get_template(html_template)
    template_vars = {"_subid_" : patient, "_study_" : study, "_actID_" : actID, "_consent_" : consentdate, "_subid_" : patient, "_embraceID_" : embID, "_comments_" : comments, "act_src" : actdata}
    html_out = template.render(template_vars)
    
    return html_out


def write_to_html(html_out, htmlfile):

    # Write to new HTML file
    with open(htmlfile, 'w') as f:
        f.write(html_out)


if __name__ == "__main__":
    
    # Define MAIN directory
    maindir = "/eris/sbdp/PHOENIX/GENERAL/DIA/"
    templatedir = "/eris/sbdp/GSP_Subject_Data/SCRIPTS/gits/custom_scripts/embrace_salvi/dpreport_embrace/"

    # Get metadata
    patient = sys.argv[1]   # First input is the patient ID (also the name of the folder)
    df0 = get_metadata("/eris/sbdp/Data/Baker/DIA/DIA.csv", patient)
    
    # Extract individual data
    study = df0['Study'].values
    patient = df0['SubjectID'].values
    consentdate = df0['Consent'].values
    comments = df0['Comments'].values
    actID = df0['actigraphyID'].values
    embID = df0['embraceID'].values

    # Paths
    parentdir = maindir + patient + "/actigraphy/processed/binned-hour/"
    actdata0 = parentdir + "reports/DIA_combined.png"
    htmlfile = parentdir + "reports/" + study + "_" + patient + "_annot_embrace_report_consent" + consentdate[0].replace('-', '') + ".html"
    pdffile = parentdir + "reports/" + study + "_" + patient + "_annot_embrace_report_consent" + consentdate[0].replace('-', '') + ".pdf"
    iconssource = templatedir + "ICONS/"
    iconsdest = parentdir[0] + "reports/ICONS/"

    # Copy ICONS folder from /.../GSP_Subject_Data/... to subject directory
    if not os.path.exists(iconsdest):
        shutil.copytree(iconssource, iconsdest, symlinks=False, ignore=None)

    # Render and output HTML file
    html_output = html_renderer("body_template.html", study[0], patient[0], consentdate[0], comments[0], actID[0], embID[0], actdata0[0])
    write_to_html(html_output, htmlfile[0])

    # Write to PDF
    # pdf = HTML(htmlfile[0]).write_pdf()
    # file(pdffile[0], 'w').write(pdf)
    