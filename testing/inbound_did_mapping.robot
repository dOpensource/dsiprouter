*** Settings ***
Documentation     Test Inbound DID
Library           SeleniumLibrary

*** Variables ***
${LOGIN URL}      http://159.65.235.14:5000/
${BROWSER}        ChromeHeadless

*** Test Cases ***
Valid Login
    Open Browser To Carrier Groups
    Input Username    admin
    Input Password    NmJhNTBlYjU4MmM4 
    Submit Credentials
    Welcome Page Should Be Open
    [Teardown]    Close Browser

*** Keywords ***
Open Browser To Login Page
    Open Browser    ${LOGIN URL}    ${BROWSER}
    Title Should Be    dSIPRouter Login

Input Username
    [Arguments]    ${username}
    Input Text    username    ${username}

Input Password
    [Arguments]    ${password}
    Input Text    password    ${password}

Submit Credentials
    Click Button    Login

Welcome Page Should Be Open
    Title Should Be    dSIPRouter Dashboard
