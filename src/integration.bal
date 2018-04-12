// Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.package sample;

import ballerina/log;
import wso2/sfdc37 as sf;
import wso2/twilio;
import ballerina/config;

documentation{
    Represents Salesforce client endpoint.
}
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

documentation{
    Represents Twilio client endpoint.
}
endpoint twilio:Client twilioClient {
    accountSid:getConfVar(TWILIO_ACCOUNT_SID),
    authToken:getConfVar(TWILIO_AUTH_TOKEN),
    clientConfig:{}
};

documentation{
    Main function to run the integration system
}
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

documentation { Returns a map consists of Lead's data
    R{{}} map consists of Lead data, phone as key, name as value
}
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

documentation { Returns the string value for config parameters
    P{{varName}} config variable name
    R{{}} string value
}
function getConfVar(string varName) returns string {
    return config:getAsString(varName) but { () => EMPTY_STRING };
}

documentation { Utility function to send SMS
    P{{fromMobile}} from mobile number
    P{{toMobile}} to mobile number
    P{{message}} sending message
}
function sendTextMessage(string fromMobile, string toMobile, string message) {
    var details = twilioClient -> sendSms(fromMobile, toMobile, message);
    match details {
        twilio:SmsResponse smsResponse => {
            log:printInfo(smsResponse.sid);
        }
        error err => log:printError(err.message);
    }
}