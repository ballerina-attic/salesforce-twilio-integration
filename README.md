# Salesforce-Twilio Integration

[Salesforce](https://www.salesforce.com) is the world’s #1 CRM platform that employees can access entirely over the Internet. 
[Twilio](https://www.twilio.com/) is a cloud communications platform for building SMS, Voice & Messaging applications on an API built for global scale. 
To understand how you can use Twilio for sending messages, let's consider a real-world use case of service promotional SMS sending system to a selected group of Leads. 

> This guide walks you through a typical cross-platform integration, which uses Ballerina to send customized SMS messages via Twilio, to a set of Leads that are taken from Salesforce.

### Available Sections:
- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)

## What you'll build

In this particular use case Salesforce gives the relational contact details of the selected Leads and 
Twilio is used to contact them via SMS to send promotional messages for the respective user group. 
This will represent a typical cross-platform integration that a marketing or promotion manager might require.

You can use Ballerina Salesforce connector to get the interested leads with their names and phone numbers 
(by sending SOQL query) and Ballerina Twilio connector to send SMS to those relevant phone numbers.
  
![alt text](https://github.com/erandiganepola/salesforce-twilio-integration/blob/master/Salesforce%20-%20Twilio%20integration.svg)

## Prerequisites

* JDK 1.8 or later
* [Ballerina Distribution](https://github.com/ballerina-platform/ballerina-lang/blob/master/docs/quick-tour.md)
* A Text Editor or an IDE
* [Salesforce Connector](https://github.com/wso2-ballerina/package-salesforce) and the [Twilio Connector](https://github.com/wso2-ballerina/package-twilio) will be downloaded from `ballerinacentral` when running the Ballerina file.

### Before you begin

##### Understand the package structure

Ballerina is a complete programming language that can have any custom project structure as you wish. Although language allows you to have any package structure, we'll stick with the following simple package structure for this project.

```
salesforce-twilio-integration 
  └── sms-sender
  |    └── test
  |          └── sms_sender_test
  |    └── constants.bal
  |    └── Package.md
  |    └── sms_sender.bal
  └── ballerina.conf
  └── README.md
```

Change the configurations in the `ballerina.conf` file. Replace "" with your data.

##### ballerina.conf
```
TWILIO_ACCOUNT_SID=""
TWILIO_AUTH_TOKEN=""
TWILIO_FROM_MOBILE=""
TWILIO_MESSAGE=""

SF_URL=""
SF_ACCESS_TOKEN=""
SF_CLIENT_ID=""
SF_CLIENT_SECRET=""
SF_REFRESH_TOKEN=""
SF_REFRESH_URL=""

```

Let's first see how to add the Salesforce configurations and Twilio configurations for the application written in Ballerina language.

#### Setup Salesforce configurations
Create a Salesforce account and create a connected app by visiting [Salesforce](https://www.salesforce.com) and obtain the following parameters:

* Base URl (Endpoint)
* Client Id
* Client Secret
* Access Token
* Refresh Token
* Refresh URL

Visit [here](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm) for more information on obtaining OAuth2 credentials.

* Set Salesforce credentials in `ballerina.conf` (Requested parameters are `SF_URL`, `SF_ACCESS_TOKEN`, `SF_CLIENT_ID`,
`SF_CLIENT_SECRET`, `SF_REFRESH_TOKEN` and `SF_REFRESH_URL`). 

`sms_sender.bal` file shows how to create the Salesforce Client endpoint (Please note getConfVar() utility function is used to get values from conf file.).

```ballerina

endpoint sf:Client salesforceClient {
    baseUrl:getConfVar(SF_URL),
    clientConfig:{
        auth:{
                scheme:"oauth",
                accessToken: getConfVar(SF_ACCESS_TOKEN),
                refreshToken:getConfVar(SF_REFRESH_TOKEN),
                clientId:getConfVar(SF_CLIENT_ID),
                clientSecret:getConfVar(SF_CLIENT_SECRET),
                refreshUrl:getConfVar(SF_REFRESH_URL)
        }
    }
};

```

#### Setup Twilio configurations
Create a [Twilio](https://www.twilio.com/) account and obtain the following parameters:

* Account SId
* Auth Token

* Set Twilio credentials in `ballerina.conf` (Required parameters are `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_MOBILE`, `TWILIO_MESSAGE`). 

`sms_sender.bal` file shows how to create the Twilio Client endpoint.

```ballerina
endpoint twilio:Client twilioClient {
    auth:{
            scheme:"basic",
            username:getConfVar(TWILIO_ACCOUNT_SID),
            password:getConfVar(TWILIO_AUTH_TOKEN)
    }
};

```
  
* IMPORTANT: These access tokens and refresh tokens can be used to make API requests on your own account's behalf. Do not share these credentials.

## Implementation

You can use SOQL queries to get SObject data. In this example a `SELECT` query has been used to get interested Leads' information.

Following function `getLeadsData()` takes query string as the parameter and returns a map consists of Leads' phone number as the key and name as the value.

```ballerina
function getLeadsData(string leadQuery) returns map {
    map leadsMap;
    log:printInfo("Salesforce Connector -> Getting query results...");

    json|sf:SalesforceConnectorError response = salesforceClient -> getQueryResult(leadQuery);
    match response {
        json jsonRes => {
            json[] records = check < json[]>jsonRes.records;
            foreach record in records{
                string key = record.Phone.toString() but { () => "" };
                string value = record.Name.toString() but { () => "" };
                leadsMap[key] = value;
            }

            if (jsonRes.nextRecordsUrl != null) {
                log:printInfo("Salesforece Connector -> getNextQueryResult()");

                while (jsonRes.nextRecordsUrl != null) {
                    log:printDebug("Found new query result set!");
                    string nextQueryUrl = jsonRes.nextRecordsUrl.toString() ?: "";
                    response = salesforceClient -> getNextQueryResult(nextQueryUrl);
                    match response {
                        json jsonNextRes => {
                            jsonRes = jsonNextRes;
                        }
                        sf:SalesforceConnectorError err => log:printError(err.message?:"");
                    }
                }
            }
        }
        sf:SalesforceConnectorError err => log:printError(err.message?:"");
    }
    return leadsMap;
}

```
Following function `sendTextMessage()` takes from-mobile number, to-mobile number and sending message as parameters and sends the request to Twilio connector inorder to send the message to relevant phone number. 

Function returns `true` if message sending gets successful (if it gets SID as return). If the SID is an empty string
or the result is an error, function returns `false`.

```ballerina
function sendTextMessage(string fromMobile, string toMobile, string message) returns boolean{
    var details = twilioClient -> sendSms(fromMobile, toMobile, message);
    match details {
        twilio:SmsResponse smsResponse => {
            log:printInfo(smsResponse.sid);
            if(smsResponse.sid != ""){
                return true;
            }
            return false;
        }
        error err => {
            log:printError(err.message);
            return false;
        }
    }
}

```
Inside sendSmsToLeads() function, it takes Leads' data by calling to getLeadsData() function. The result map
is iterated and not null phone numbers are taken. Customized messages are prepared and sent to relevant Leads' phone numbers.
Function returns `true` if at least one message is being sent to a Lead, if not `false`.

```ballerina
function sendSmsToLeads(string sfQuery) returns boolean  {
    boolean success = false;

    map leadsDataMap = getLeadsData(sfQuery);
    string message = getConfVar(TWILIO_MESSAGE);
    string fromMobile = getConfVar(TWILIO_FROM_MOBILE);

    log:printInfo("Twilio Connector => Sending messages...");
    foreach k, v in leadsDataMap {
        string|error result = <string>v;
        match result {
            string value => {
                if (k != EMPTY_STRING) {
                    message = "Hi " + value + NEW_LINE_CHARACTER + message;
                    boolean response = sendTextMessage(fromMobile, k, message);
                    if(response){
                        success = response;
                    }
                }
            }
            error err => {
                log:printError(err.message);
            }
        }
    }
    return success;
}
```

Inside the main function, it calls to `sendSmsToLeads()` by passing the requested query.
Result status can be checked with the `boolean` value.
```ballerina

function main(string[] args) {
    log:printInfo("Salesforce-Twilio Integration -> Main function");
    boolean result = sendSmsToLeads("SELECT name, phone FROM Lead");

    if(result){
        log:printInfo("Salesforce-Twilio Integration -> SMS Sending Successful!");
    } else {
        log:printInfo("Salesforce-Twilio Integration -> SMS Sending Failed!");
    }
}

```

## Testing

You can use `Testerina` to test Ballerina implementations. 
Run `sms_sender_test.bal` file using following command `ballerina run sms-sender` to execute the test function.

```ballerina
@test:Config
function testSendSmsToLeads () {
    string sampleQuery = "SELECT name, phone FROM Lead";

    log:printInfo("Salesforce-Twilio Integration => sendSMS()");

    boolean result = sendSmsToLeads(sampleQuery);
        test:assertEquals(result, true, msg = "Unsuccessful!!");
}

```

* You will receive SMS for the relevant numbers as the result.

#### Sample Result SMS
```
Hi Carmen

Enjoy discounts up to 25% by downloading our new Cloud Platform before 31st May'18! T&C Apply.
```
#### Terminal Output 

You will get logs with Twilio SID number as below if it's successful. If failed, you will get logs with error messages.

```ballerina
...
2018-04-12 13:27:13,869 INFO  [src] - Salesforce Connector -> Getting query results... 
2018-04-12 13:27:15,718 INFO  [src] - Twilio Connector => Sending messages... 
2018-04-12 13:27:17,061 INFO  [src] - SM08134284d310461aa7dd4b20d8d2a7b5 
2018-04-12 13:27:17,378 INFO  [src] - SM1f40e267c0c2489a9a8ae2172665647f 
...

```
