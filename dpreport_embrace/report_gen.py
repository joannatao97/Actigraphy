import pandas as pd
import numpy as np
from jinja2 import Environment, FileSystemLoader
from weasyprint import HTML
# import pdfkit

def get_metadata(metadatafile, patientID):
    
    # Gather metadata information for a single subject ID to put into file
    df = pd.read_csv(metadatafile)
    patient_metadata = df.loc[df['SubjectID'] == patientID]

    return patient_metadata


def html_renderer(html_template, study, patient, consentdate, comments, actID, embID, actdata):

    # Use HTML template and replace all {{___}} with appropriate variables
    env = Environment(loader=FileSystemLoader('.'))
    template = env.get_template(html_template)
    template_vars = {"_subid_" : patient, "_study_" : "DIA", "_actID_" : actID, "_consent_" : consentdate, "_subid_" : patient, "_embraceID_" : embID, "_comments_" : comments, "act_src" : actdata}
    html_out = template.render(template_vars)
    
    return html_out


def write_to_html(html_out, htmlfile):

    # Write to new HTML file
    with open(htmlfile, 'w') as f:
        f.write(html_out)


if __name__ == "__main__":
    
    # Paths
    patient = "C3LMM"
    parentdir = "/Users/joshsalvi/Documents/Lab/Lab/Baker/Actigraphy/" + patient + "/"
    actdata0 = parentdir + "DIA_combined.png"
    htmlfile = parentdir + "DIA_" + patient + "_annot_embrace_report.html"
    pdffile = parentdir + "DIA_" + patient + "_annot_embrace_report.pdf"

    # Get metadata
    df0 = get_metadata("/Users/joshsalvi/Documents/Lab/Lab/Baker/Actigraphy/DIA.csv", patient)

    # Extract individual data
    study = df0['Study'].values
    patient = df0['SubjectID'].values
    consentdate = df0['Consent'].values
    comments = df0['Comments'].values
    actID = df0['actigraphyID'].values
    embID = df0['embraceID'].values

    # Render and output HTML file
    html_output = html_renderer("body_template.html", study[0], patient[0], consentdate[0], comments[0], actID[0], embID[0], actdata0)
    write_to_html(html_output, htmlfile)

    # Write to PDF
    pdf = HTML(htmlfile).write_pdf()
    file(pdffile, 'w').write(pdf)
    