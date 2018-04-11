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
// under the License.

import ballerina/io;
import ballerina/log;
import wso2/sfdc37 as sf;

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

function getLeadsData() returns map{
    map m;
    log:printInfo("salesforceClient -> getQueryResult()");
    string sampleQuery = "SELECT name, phone FROM Lead";
    json|sf:SalesforceConnectorError response = salesforceClient -> getQueryResult(sampleQuery);
    match response {
        json jsonRes => {
            json[] records = check < json[]>jsonRes.records;
            foreach record in records{
                string key = record.Phone.toString() but {() => ""};
                string value = record.Name.toString() but {() => ""};
                m[key] = value;
            }

            if (jsonRes.nextRecordsUrl != null) {
                log:printInfo("salesforceClient -> getNextQueryResult()");

                while (jsonRes.nextRecordsUrl != null) {
                    log:printDebug("Found new query result set!");
                    string nextQueryUrl = jsonRes.nextRecordsUrl.toString() ?: "";
                    response = salesforceClient -> getNextQueryResult(nextQueryUrl);
                    match response {
                        json jsonNextRes => {
                            jsonRes = jsonNextRes;
                        }
                        sf:SalesforceConnectorError err => {
                            io:println(err);
                        }
                    }
                }
            }
        }
        sf:SalesforceConnectorError err => {
            io:println(err);
        }
    }
    return m;
}