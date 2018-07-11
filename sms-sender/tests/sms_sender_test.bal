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
// under the License.package sms-sender.tests;

import ballerina/log;
import ballerina/test;

@test:Config
function testSendSmsToLeads() {
    log:printDebug("Salesforce-Twilio Integration -> Sending promotional SMS to leads of Salesforce");
    string sampleQuery = "SELECT Name, Phone, Country FROM Lead WHERE Country = 'LK'";
    boolean result = sendSmsToLeads(sampleQuery);
    if (result) {
        log:printDebug("Salesforce-Twilio Integration -> Promotional SMS sending process successfully completed!");
    } else {
        log:printDebug("Salesforce-Twilio Integration -> Promotional SMS sending process failed!");
    }
}