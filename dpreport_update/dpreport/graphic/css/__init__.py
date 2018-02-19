from tools import parser
def get_dpr():
    return '''
    html {
        width: 100%;
        height: 100%;
    }
    body {
        width: 98%;
        height: 98%;
        margin: 0px;
        padding: 8px;
    }
    .reportHeader {
        width: 100%;
    }
    .reportInformation {
        width: 30%;
        display: inline-block;
        white-space: nowrap;
        vertical-align: bottom;
    }
    #logo {
        font-size: 28px;
        font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
        color: #d3d3d3;
        font-weight: 100;
        font-variant: small-caps;
    }
    #timestamp {
        margin-top: 8px;
        margin-left: 4px;
        margin-right: 4px;
        margin-bottom: 2px;
        font-size: 10px;
        font-family: 'Courier New', Courier, monospace;
        color: rgba(0,0,0,0.4);
    }
    table.reportMetadata {
        width: 69%;
        display: inline-block;
        white-space: nowrap;
        vertical-align: bottom;
        font-size: 10px;
        font-family: Helvetica,Arial,sans-serif;
        border-spacing:0px;
        border-collapse: collapse;
    }
    table.reportMetadata tbody {
        width: 100%;
        display: table;
    }
    table.reportMetadata td.reportMetadataHeader {
        color: rgba(0,0,0,0.5);
    }
    table.reportMetadata td.reportMetadataItem {
        color: rgba(0,0,0,0.8);
    }
    .reportBody {
        width: 100%;
        margin-top: 8px;
        font-size: 12px;
        font-family: Arial, Helvetica, sans-serif;
        color: rgba(0,0,0,0.9);
    }
    .reportCategory {
        width: 100%;
        text-align: center;
        padding: 4px;
        border-top: 1px solid rgba(0,0,0,0.2);
    }
    .reportItem {
        width: 100%;
        padding: 4px;
    }
    .reportItemDescription {
        display: inline-block;
        white-space: nowrap;
        font-size: 10px;
    }
    .reportItemDescription .reportItemDescriptionHeader {
        color: rgba(0,0,0,0.7);
    }
    .reportItemDescription .reportItemDescriptionDetail {
        color: rgba(0,0,0,0.5);
    }
    .reportItemImage {
        display: inline-block;
        white-space: nowrap;
    }
    .reportItemImage .reportItemDataImage {
        width: 90%;
    }
    .reportItemImage .reportItemLegendImage {
        width: 10%;
    }
    '''
