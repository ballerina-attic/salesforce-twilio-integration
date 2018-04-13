import ballerina/log;
import ballerina/test;

@test:Config
function testSendSMS () {
    string sampleQuery = "SELECT name, phone FROM Lead";

    log:printInfo("Salesforce-Twilio Integration => sendSMS()");

    boolean result = sendSmsToLeads(sampleQuery);
        test:assertEquals(result, true, msg = "Unsuccessful!!");
}