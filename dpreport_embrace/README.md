------------------------------------
**DP REPORT GENERATOR FOR EMBRACE DATA**
------------------------------------

**Dependencies:**
* `pandas`
* `numpy`
* `jinja2`
* `weasyprint`

**Run:**
  `python3 report_gen.py {patientID}`

**File Requirements:**
* `/.../DIA.csv`:  contains metadata for all patients in the study
* `/.../DIA_combined.png`:  results generated from autogplot.sh
* `/.../body_template.html`:  HTML template for generating the HTML report

*Please note that the report will be generated in the patient's study folder on the server.*
*The report is titled `DIA_{metadata}_report.html`.*

**Author:**     **Joshua D. Salvi**

**Year:**       **2018**