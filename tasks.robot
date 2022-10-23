# +
*** Settings ***
Documentation   The following robot is meant as a certification robot 
...             It follows the second certification from RoboCorp.
...             The purpose of this robot is to use an order list to 
...             recreate orders and save the picture and invoice from 
...             all the orders.
...             After it's embeddded in a pdf with the invoice the robot 
...             will save it in a zip file.

Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           OperatingSystem 
Library           RPA.Robocorp.Vault
# -


*** Keywords ***
Get Order Link
    ${secret}=    Get Secret    credentials
    # Note: in real robots, you should not print secrets to the log. this is just for demonstration purposes :)
    [Return]    ${secret}[password]

*** Keywords ***
Download The csv File
    ${secretWebsite}=    Get Order Link
    Download    ${secretWebsite}    overwrite=True

*** Keywords ***
Get Orders
    ${orders}=   Read table from CSV     orders.csv
    [Return]     ${orders}  

*** Keywords ***
Insert Data From csv
    [Arguments]     ${sale}
    Select From List By Value   head    ${sale}[Head]
    Click Element   id:id-body-${sale}[Body]
    Input Text      //form/div[3]/input   ${sale}[Legs]
    Input Text      address     ${sale}[Address]
    Click Button    Preview

***Keywords***
Press Order
    Click Button    order
    Element Should Be Visible    id:receipt

*** Keywords ***
Open Website
    ${website}=    Insert Website
    Open Available Browser    ${website}

*** Keywords ***
Insert Website
    Add heading       Please input the website
    Add text          https://robotsparebinindustries.com/#/robot-order
    Add text input    message
    ${website}=       Run dialog
    [Return]    ${website.message}

*** Keywords ***
Press OK To Pop Up
    Click Button    OK

*** Keywords ***
Store the receipt as a PDF file 
    [Arguments]     ${orderNumber}
    Wait Until Element Is Visible       id:receipt
    ${receipt-html}=    Get Element Attribute    id:receipt    innerHTML
    Html To Pdf    ${receipt-html}    ${CURDIR}${/}output${/}receipt-${orderNumber}.pdf
    [Return]       ${CURDIR}${/}output${/}receipt-${orderNumber}.pdf


*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    Screenshot     id:robot-preview-image    ${CURDIR}${/}output${/}preview-${orderNumber}.png
    [Return]       ${CURDIR}${/}output${/}preview-${orderNumber}.png


*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf
    Remove File    ${screenshot}


*** Keywords ***
Go to order another robot
    Click Button    order-another


*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip  ${CURDIR}${/}output  Receipts.zip


*** Keywords ***
Close The Browser
        Close Browser

*** Tasks ***
Insert data and then embed the picture in the invoice and zip all the invoices
    Download The csv File
    Open Website
    ${orders}=   Get Orders
    FOR     ${row}     IN      @{orders}
        Press OK To Pop Up
        Insert Data From csv    ${row}
        Wait Until Keyword Succeeds    25x    0.1 sec    Press Order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close The Browser
