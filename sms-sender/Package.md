# Salesforce Twilio Integration

## What is Salesforce and Twilio

[Salesforce](https://www.salesforce.com) is the world’s #1 CRM platform that employees can access entirely over the Internet. It brings together all your customer information in a single, integrated platform that enables you to build a customer-centred business from marketing right through to sales, customer service and business analysis.

[Twilio](https://www.twilio.com/) is a cloud communications platform for building SMS, Voice & Messaging applications on an API built for global scale.

> This guide walks you through a typical cross-platform integration, which uses Ballerina to send customized SMS messages via Twilio, to a set of leads that are taken from Salesforce.

## What you'll build

To understand how you can use Twilio for sending messages, let's consider a real-world use case of service promotional SMS sending system. 

In this particular use case Salesforce gives the relational contact details of the selected Leads and Twilio is used to contact them via SMS to send promotional messages for the respective user group. This will represent a typical cross-platform integration that a marketing or promotion manager might require.

You can use Ballerina Salesforce connector to get the interested leads with their names and phone numbers and Ballerina Twilio connector to send SMS to those relevant phone numbers.
  