*** Settings ***
Documentation       Example robot that allows a human to search for a specific
...                 search query in Google Images.

Library             RPA.Browser.Selenium
Library             RPA.Assistant
Library             Collections

Suite Teardown      Close All Browsers


*** Variables ***
${BROWSER_OPEN}                 ${FALSE}
${URL_GOOGLE_IMAGE_SEARCH}      https://images.google.com
${URL_WIKIPEDIA}                https://en.wikipedia.org/wiki/Main_Page


*** Test Cases ***
Repeated
    Prepare Browser

    FOR    ${i}    IN RANGE    99999
        ${search_query}=    Collect search query from user
        Run Keyword And Ignore Error    Exit For Loop If    ${search_query} == ${False}
        Run Keyword    Search And Handle Errors    ${search_query}
    END
    Close All Browsers
    Set Global Variable    ${BROWSER_OPEN}    ${FALSE}


*** Keywords ***
Prepare Browser
    Open Available Browser    ${URL_GOOGLE_IMAGE_SEARCH}
    Close Google Sign in if shown
    Reject Google Cookies
    Accept Google Consent

    Execute Javascript    window.open('${URL_WIKIPEDIA}', '_blank');

Reject Google Cookies
    Click Element If Visible    xpath://button/div[contains(text(), 'Reject all')]

Accept Google Consent
    Click Element If Visible    xpath://button/div[contains(text(), 'Accept all')]

Close Google Sign in if shown
    Click Element If Visible    No thanks

Search Google Images
    [Arguments]    ${search_query}
    ${window_titles}=    Get Window Titles
    Switch Window    ${window_titles}[0]
    Input Text    name:q    ${search_query}
    Submit Form

Collect the first search result image
    Wait Until Element Is Visible    css:div[data-ri="0"]    timeout=15
    Screenshot    css:div[data-ri="0"]
    ...    filename=%{ROBOT_ROOT}${/}output${/}image_from_google.png

Search Wikipedia
    [Arguments]    ${search_query}
    ${window_titles}=    Get Window Titles
    Switch Window    ${window_titles}[1]
    Input Text When Element Is Visible    name=search    ${search_query}
    Submit Form    xpath=//*[@id="searchform"]

Search And Handle Errors
    [Arguments]    ${search_query}
    TRY
        Search Google Images    ${search_query}
        Collect the first search result image
        Search Wikipedia    ${search_query}
    EXCEPT
        Capture Page Screenshot    %{ROBOT_ARTIFACTS}${/}error.png
        Fail    Checkout the screenshot: error.png
    END

Collect search query from user
    FOR    ${i}    IN RANGE    5    # Arbitrary large number to prevent infinite loop
        Add text input    search    label=Search query
        Add Submit Buttons    buttons=Submit,Close    default=Submit
        ${response}=    Run dialog    height=200
        ${button_pressed}=    Set Variable    ${response['submit']}
        IF    '${button_pressed}' == 'Close'    BREAK
        ${keys}=    Get Dictionary Keys    ${response}
        IF    'search' not in ${keys}    CONTINUE
        ${search_query}=    Set Variable    ${response['search']}
        IF    '${search_query}' != ''    BREAK
        Log    No input provided, prompting again...
    END
    IF    '${button_pressed}' == 'Close'    RETURN    ${False}
    RETURN    ${search_query}
