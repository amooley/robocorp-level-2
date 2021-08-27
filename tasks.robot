# +
*** Settings ***
Documentation   Robot to order more Robots
...             Download Orders CSV
...             Create order for every row in CSV
...             Download and save receipt as PDF
...             Add ordered Robot screenshot to the PDF
...             Create ZIP of all the receipts

Library     RPA.HTTP
Library     RPA.Excel.Files
Library     RPA.Browser.Selenium
Library     RPA.PDF
Library     RPA.Tables
Library     RPA.Archive
Library     RPA.Dialogs
Library     RPA.Robocloud.Secrets
# -


*** Keywords ***
Download Orders Csv
    [Arguments]     ${orderLink}
    Download    ${orderLink}      overwrite=True

*** Keywords ***
Close That Popup
    Click Element When Visible    css: button.btn.btn-dark

*** Keywords ***
Open Robot Order Website
    ${orderUrl}=    Get Secret    data
    Open Available Browser      ${orderUrl}[url]

*** Keywords ***
Save Order And Robot Screenshot to PDF
    [Arguments]     ${orderNumber}
    ${orderReceipt}=   Get Element Attribute    id:receipt    outerHTML
    ${pdf}      Set Variable     ${CURDIR}${/}output${/}${orderNumber}.pdf
    Html To Pdf    ${orderReceipt}    ${pdf}
    
    ${screenshot}   Set Variable      ${CURDIR}${/}screenshot${/}${orderNumber}.png
    Capture Element Screenshot      id:robot-preview-image      ${screenshot}
    
    Open PDF    ${CURDIR}${/}output${/}${orderNumber}.pdf
    ${file}=   Create List     ${screenshot}
    
    Add Files To Pdf    ${file}     ${pdf}      True
    Close Pdf   ${pdf}

*** Keywords ***
Fill Order Form Using Csv Data
    ${orders}=      Read table from CSV    orders.csv
    
    FOR    ${order}    IN    @{orders}
        Close That Popup
        Create Order      ${order}
        Save Order And Robot Screenshot to PDF  ${order}[Order number]
        Click Button    id:order-another
    END

*** Keywords ***
Create Order
    [Arguments]     ${order}
    Select From List By Value    head       ${order}[Head]
    Select Radio Button       body    ${order}[Body]
    Input Text        css:input.form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    id:preview
    Click Button    id:order
    
    FOR    ${i}    IN RANGE    9999
        ${orderError}=      Does Page Contain Element    css:div.alert-danger
        IF  ${orderError}
            Click Button    id:order
        ELSE
            Exit For Loop
        END
    END
        

*** Keywords ***
Create Orders
    [Arguments]     ${orders}
    No Operation

*** Keywords ***
Create Zip File Of Receipts
    Archive Folder With Zip    ${CURDIR}${/}output    receipts.zip

*** Keywords ***
Get Link to Orders
    Add text input    orderLink
    ...     label=Enter link to orders CSV file
    ...     placeholder=Add link here
    ${result}=      Run dialog
    [Return]        ${result.orderLink}

*** Tasks ***
Order Robot from Robot Spare Bin Industries
    # https://robotsparebinindustries.com/orders.csv
    ${orderLink}=      Get Link to Orders
    Download Orders Csv   ${orderLink}
    Open Robot Order Website
    Fill Order Form Using Csv Data
    Create Zip File Of Receipts
