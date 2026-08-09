# Email Header Guide
- Read Received headers bottom-up: the bottom-most Received line contains the originating MTA IP.
- Authentication-Results summarizes SPF, DKIM, and DMARC alignment.
- Return-Path should align with the domain in the From header.
