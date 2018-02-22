import pandas as pd
import numpy as np
import sys

if __name__ == "__main__":

    # Parent directory
    parentdir = "/Users/joshsalvi/Documents/Lab/Lab/Baker/geneactiv/Technical/example_run_data/"

    # Study and patient information
    study = "DIA"
    # subject = sys.argv[1]   # First input is patient ID
    subject = "00001"
    device = "geneactiv"

    # Files to analyze
    metafile = parentdir + study + "_" + subject + "_" + device + "_raw.csv_metadata.csv"
    datafile = parentdir + study + "_" + subject + "_" + device + "_raw.csv_rawdata.csv"

    # Create dataframes
    df_meta = pd.read_csv(metafile)
    df_data = pd.read_csv(datafile)
    
    # Split into 1-minute chunks
    sample_rate = df_meta.loc[df_meta['Device Type']=='Measurement Frequency'].values
    sample_rate = int(sample_rate[0][1].replace(' Hz',''))
    num_points = 60*sample_rate

    print(df_data)

