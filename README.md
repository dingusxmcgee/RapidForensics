# CrowdStrike Fusion Workflows for Velociraptor Forensic Collection

## Overview

This repository contains the files and implementation steps needed to configure **CrowdStrike Fusion Workflows** to run a **Velociraptor offline collector** and collect forensic artifacts from Windows-based hosts.

> [!IMPORTANT]
> These workflows assume that the Velociraptor offline collector is configured to upload the forensic collection ZIP file to an **Azure Storage blob**. Scripts and workflow settings must be modified if your environment or collection goals differ.
> The workflows rely on several PowerShell scripts to query the host and perform actions. You may need to customize these scripts or add functionality to meet the requirements of your environment.

## Included Workflows

### On-Demand Rapid Forensic Collection

This is an on-demand, ad hoc workflow. It accepts either a hostname or an Agent ID (`aid`). If a hostname is provided, the workflow translates it to the corresponding `aid` via a simple logscale search.

The workflow performs the following actions:

1. Checks whether an offline collector is already running. If a collector is already running, the workflow aborts and sends you an email, notifying you that it WOULD have run, bu one is already running.
2. Places the collector executable on the host and runs it.
3. Waits for the collector to finish.
4. Checks in a loop until the collector has finished uploading to Azure.
5. Collects the local collector log file.
6. Emails you the collector log along with some host and execution details.
7. Requests human approval via the same email to delete the collection ZIP file from the host.

If no approval response is received within 24 hours, the workflow defaults to leaving the ZIP file on the host.

### Detection-Based Rapid Forensic Collection

This workflow uses a detection trigger, such as a **critical detection** or an **OverWatch detection**, and otherwise follows the same collection process as the on-demand workflow. The trigger can be modified to match your requirements.

#### Duplicate-execution safety check

The primary difference is a safety check designed to prevent unnecessary repeated collections from the same host.

CrowdStrike may generate multiple detections of the same severity for a single endpoint action. This can cause several workflow instances to execute simultaneously. To reduce duplicate collection attempts, the workflow queries LogScale to determine whether the collector process has run within the past 24 hours. This time window can be easily modified to meet your requirements.

- If the collector has run within the configured period, the workflow does not start another collection and will notify you via email.
- If multiple triggering detections occur within a very short time window only one workflow instance will properly run/complete, and the others will fail when they try to put and run the same collector executable. This is a quirk of the workflow/rtr process, but is the desired outcome anyway.
- The side effect of this is additional email notifications.

In observed testing, the `ProcessRollup2` event containing the first collector execution may not reach LogScale quickly enough to stop near-simultaneous workflow executions. These workflows can start within milliseconds or one to two seconds of one another, which is not enough time for the log to populate and be searchable to prevent the workflow from running.

To run another collection intentionally, use the **On-Demand Rapid Forensic Collection** workflow. The on-demand workflow does not check for previous collector executions.

## Repository Contents

- Fusion workflow files in YAML format
- PowerShell (`.ps1`) scripts for host actions
- Workflow diagrams in the following formats:
  - Text
  - Image
  - Mermaid source for diagram-tool import

## Implementation Steps

### Step 0: Create and upload the offline collector

1. Create the offline collector in Velociraptor.
2. Test the collector in a standalone fashion before implementing the workflow, ensure the collector and upload process(if in use) is working as intended.
3. Upload its executable to **CrowdStrike Response Scripts and Files**.

### Step 1: Configure the collector process check

Modify `IsForensicCollectorRunning-WIN.ps1` to match the naming convention used by your Velociraptor offline collector.

### Step 2: Create the response scripts

Create all provided scripts in **CrowdStrike Response Scripts and Files** and configure their output schemas.

> [!IMPORTANT]
> Ensure every required script is marked **Available to workflows**.

### Step 3: Import the workflow

Import the appropriate workflow YAML file into **CrowdStrike Fusion Workflows**.

### Step 4: Rename the workflow

Change the workflow name to match your environment, if desired.

### Step 5: Map the script actions

Update the script actions throughout the imported workflow so that they reference the scripts created in Step 2.

This should not cause errors in subsequent actions or conditions as long as the output schemas are correct. If downstream workflow errors occur, confirm that each configured output schema matches the corresponding script variable output.

### Step 6: Configure the collector executable

Modify the **Put and Run File** action to use the uploaded Velociraptor offline collector. The collector executable should be available as a dropdown selection.

### Step 7: Configure email notifications

Update every email action with the desired recipient address. Modify the email content as needed for your environment.

### Step 8: Test the workflow

Test the workflow before production use.

The collection process is not destructive. If desired, insert **Sleep** actions between workflow actions. This provides time to start the workflow, review its status, and verify earlier actions before the workflow begins longer-running steps such as executing the collector.


