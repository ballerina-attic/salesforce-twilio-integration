# Salesforce Twilio Integration

## What is Salesforce and Twilio

[Salesforce](https://www.salesforce.com) is the world’s #1 CRM platform that employees can access entirely over the Internet. It brings together all your customer information in a single, integrated platform that enables you to build a customer-centred business from marketing right through to sales, customer service and business analysis.

[Twilio](https://www.twilio.com/) is a cloud communications platform for building SMS, Voice & Messaging applications on an API built for global scale.

> This guide walks you through a typical cross-platform integration, which uses Ballerina to send customized SMS messages via Twilio, to a set of leads that are taken from Salesforce.

### Available Sections:
- [What you'll build](#what-youll-build)
- [Prerequisites](#prerequisites)
- [Implementation](#implementation)
- [Testing](#testing)

## What you'll build

To understand how you can use Twilio for sending messages, let's consider a real-world use case of service promotional SMS sending system. 

In this particular use case Salesforce gives the relational contact details of the seleted Leads and Twilio is used to contact them via SMS to send promotional messages for the respective user group. This will represent a typical cross-platform integration that a marketing or promotion manager might require.

You can use Ballerina Salesforce connector to get the interested leads with their names and phone numbers and Ballerina Twilio connector to send SMS to those relevant phone numbers.
  
## Prerequisites

* JDK 1.8 or later
* [Ballerina Distribution](https://github.com/ballerina-platform/ballerina-lang/blob/master/docs/quick-tour.md)
* A Text Editor or an IDE
* [Salesforce Connector](https://github.com/wso2-ballerina/package-salesforce) and the [Twilio Connector](https://github.com/wso2-ballerina/package-twilio) will be downloaded from `ballerinacentral` when running the Ballerina file.

### Before you begin

Understand the package structure
Ballerina is a complete programming language that can have any custom project structure as you wish. Although language allows you to have any package structure, we'll stick with the following simple package structure for this project.

```
salesforce-twilio-integration
  ├── .ballerina 
  └── ballerina.conf
  └── src
      └── constants.bal
      └── integration.bal
      └── Package.md
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
SF_REFRESH_TOKEN_ENDPOINT=""
SF_REFRESH_TOKEN_PATH=""
```

Let's consider `integration.bal` for example. Let's first see how to add the Salesforce configurations, which require OAuth2 configurations and Twilio configurations for the application written in Ballerina language.

#### Setup OAuth2 configurations (for Salesforce Connector)
Create a Salesforce account and create a connected app by visiting [Salesforce](https://www.salesforce.com) and obtain the following parameters:

* Base URl (Endpoint)
* Client Id
* Client Secret
* Access Token
* Refresh Token
* Refresh Token Endpoint
* Refresh Token Path

Visit [here](https://help.salesforce.com/articleView?id=remoteaccess_authenticate_overview.htm) for more information on obtaining OAuth2 credentials.

* Set Salesforce credentials in `ballerina.conf` (Parameters are `SF_URL`, `SF_ACCESS_TOKEN`, `SF_CLIENT_ID`,
`SF_CLIENT_SECRET`, `SF_REFRESH_TOKEN`, `SF_REFRESH_TOKEN_ENDPOINT` and `SF_REFRESH_TOKEN_PATH`). 

`integration.bal` file shows how to create the Salesforce Client endpoint.

```ballerina

endpoint sf:Client salesforceClient {
    oauth2Config:{
        accessToken:getConfVar(SF_ACCESS_TOKEN),
        baseUrl:getConfVar(SF_URL),
        clientId:getConfVar(SF_CLIENT_ID),
        clientSecret:getConfVar(SF_CLIENT_SECRET),
        refreshToken:getConfVar(SF_REFRESH_TOKEN),
        refreshTokenEP:getConfVar(SF_REFRESH_TOKEN),
        refreshTokenPath:getConfVar(SF_REFRESH_TOKEN_PATH),
        clientConfig:{}
    }
};

```

#### Setup Twilio configurations
Create a [Twilio](https://www.twilio.com/) account and obtain the following parameters:

* Account SId
* Auth Token

* Set Twilio credentials in `ballerina.conf` (Required parameters are `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM_MOBILE`, `TWILIO_MESSAGE`). 

`integration.bal` file shows how to create the Salesforce Client endpoint.

```ballerina
endpoint twilio:Client twilioClient {
    accountSid:getConfVar(TWILIO_ACCOUNT_SID),
    authToken:getConfVar(TWILIO_AUTH_TOKEN),
    clientConfig:{}
};
```
  
* IMPORTANT: These access tokens and refresh tokens can be used to make API requests on your own account's behalf. Do not share these credentials.

## Implementation

Following function `getLeadsData()` takes query string as parameter and returns a map consists of Lead's phone number as key and name as value.

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
                        sf:SalesforceConnectorError err => log:printError(err.messages[0]);
                    }
                }
            }
        }
        sf:SalesforceConnectorError err => log:printError(err.messages[0]);
    }
    return leadsMap;
}

```
Followinf function `sendTextMessage()` takes from-mobile number, to-mobile number and sending message as parameters and sends the request to Twilio connector.

```ballerina
function sendTextMessage(string fromMobile, string toMobile, string message) {
    var details = twilioClient -> sendSms(fromMobile, toMobile, message);
    match details {
        twilio:SmsResponse smsResponse => {
            log:printInfo(smsResponse.sid);
        }
        error err => log:printError(err.message);
    }
}

```
Inside the main function, it calls to `getLeadsData()` and get needed Lead's data and prepare the customozed SMS. Then send those SMSs to relevant Leads by calling to `sendTextMessage()` function. 

```ballerina

function main(string[] args) {

    string sampleQuery = "SELECT name, phone FROM Lead";

    map leadsDataMap = getLeadsData(sampleQuery);
    string message = getConfVar(TWILIO_MESSAGE);
    string fromMobile = getConfVar(TWILIO_FROM_MOBILE);

    log:printInfo("Twilio Connector => Sending messages...");
    foreach k, v in leadsDataMap {
        string|error result = <string>v;
        match result {
            string value => {
                if (k != EMPTY_STRING) {
                    message = "Hi " + value + NEW_LINE_CHARACTER + message;
                    sendTextMessage(fromMobile, k, message);
                }
            }
            error err => log:printError(err.message);
        }
    }
}

```

## Testing

Run `integration.bal` file using following command `ballerina run src` to excute the main function.

* You will receive SMS for the relevant numbers as the result.

#### Sample Result SMS
```
Hi Carmen

Enjoy discounts up to 25% by downloading our new Cloud Platform before 31st May'18! T&C Apply.
```
#### Terminal Output 

You will get logs with Twilio SID number as below if success. If failed, logs with error messages.

```ballerina
2018-04-12 13:27:13,869 INFO  [src] - Salesforce Connector -> Getting query results... 
2018-04-12 13:27:15,718 INFO  [src] - Twilio Connector => Sending messages... 
2018-04-12 13:27:17,061 INFO  [src] - SM08134284d310461aa7dd4b20d8d2a7b5 
2018-04-12 13:27:17,378 INFO  [src] - SM1f40e267c0c2489a9a8ae2172665647f 

```
