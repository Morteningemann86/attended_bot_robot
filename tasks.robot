*** Settings ***
Documentation       Example robot that allows a human to search for a specific
...                 search query in Google Images.

Library             RPA.Browser.Selenium
Library             RPA.Assistant
Library             Collections

Suite Teardown      Close All Browsers

*** Variables ***
${BROWSER_OPEN}    ${FALSE}

*** Keywords ***
Open Browser If Not Open
    IF    ${BROWSER_OPEN} == ${FALSE}
        Open Available Browser    https://images.google.com
        Set Global Variable    ${BROWSER_OPEN}    ${TRUE}
    ELSE
        Go To    https://images.google.com
    END

Reject Google Cookies
    Click Element If Visible    xpath://button/div[contains(text(), 'Reject all')]

Accept Google Consent
    Click Element If Visible    xpath://button/div[contains(text(), 'Accept all')]

Close Google Sign in if shown
    Click Element If Visible    No thanks

Search Google Images
    [Arguments]    ${search_query}
    Open Browser If Not Open
    Close Google Sign in if shown
    Reject Google Cookies
    Accept Google Consent
    Input Text    name:q    ${search_query}
    Submit Form

Collect the first search result image
    Wait Until Element Is Visible    css:div[data-ri="0"]    timeout=15
    Screenshot    css:div[data-ri="0"]
    ...    filename=%{ROBOT_ROOT}${/}output${/}image_from_google.png

Search And Handle Errors
    [Arguments]    ${search_query}
    TRY
        Search Google Images    ${search_query}
        Collect the first search result image
    EXCEPT
        Capture Page Screenshot    %{ROBOT_ARTIFACTS}${/}error.png
        Fail    Checkout the screenshot: error.png
    END

Collect search query from user
    Add text input    search    label=Search query
    Add Submit Buttons    buttons=Submit,Close    default=Submit
    ${response}=    Run dialog    height=200
    ${button_pressed}=    Set Variable    ${response['submit']}
    IF    '${button_pressed}' == 'Close'
        RETURN    ${False}
    END
    RETURN    ${response['search']}

*** Test Cases ***
Repeated Search
    FOR    ${i}    IN RANGE    99999    # Large number to simulate 'infinite' loop
        ${search_query}=    Collect search query from user
        Run Keyword And Ignore Error    Exit For Loop If    ${search_query} == ${False}     # or ${search_query} == ${False}
        Run Keyword    Search And Handle Errors    ${search_query}
        Log    Enter 'EXIT' or press 'Close' to stop or provide a new query to continue.
    END
    Close All Browsers
    Set Global Variable    ${BROWSER_OPEN}    ${FALSE}

