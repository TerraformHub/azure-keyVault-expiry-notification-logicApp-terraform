# Azure Key Vault Expiry Notification Logic App with Terraform

This project deploys an Azure Logic App using Terraform to monitor Azure Key Vault secrets and send notifications when they are nearing expiration.

## Overview

This is an end-to-end solution for notifying users about expiring Key Vault secrets through a Logic App.

### Problem

When your Key Vault secrets or certificates are nearing expiration, timely notifications are essential. This solution leverages Azure Logic Apps to send daily email notifications for secrets that are set to expire within 30 days. This advance warning allows you ample time to update or renew the secrets.

### Solution

- **Email Notifications:** The Logic App sends notifications via Azure Communication Services (ACS), ensuring reliable email delivery.
  
- **Log Analytics Integration:** Expiring and expired secrets are logged in Azure Log Analytics, allowing for further analysis and visibility. A custom table is created to store this data, which can be queried and pinned to your Azure dashboard for real-time insights.

- **Daily Triggers:** The Logic App is configured to trigger every 24 hours, ensuring you receive daily reminders until the secrets are updated or renewed.

## Getting Started

1. **Prerequisites:** 
   - Azure subscription
   - Terraform installed

2. **Deployment Steps:**
   - Clone the repository.
   - Configure the Terraform scripts with your Azure environment details.
   - Deploy the Logic App using Terraform.

3. **Monitoring:**
   - Access Azure Log Analytics to view the custom table for near-expiring and expired secrets.
   - Pin the relevant queries to your dashboard for quick access.

