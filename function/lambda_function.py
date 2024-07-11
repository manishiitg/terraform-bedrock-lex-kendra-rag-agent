import os
import logging
import boto3
import jsonpickle
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

client = boto3.client('lambda')

bedrock_runtime = boto3.client('bedrock-runtime')


def process_prompt(system, prompt):
    body = json.dumps({
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 2048,
        "system": system,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": prompt
                    }
                ]
            }
        ]
    })

    response = bedrock_runtime.invoke_model(
        modelId="anthropic.claude-3-sonnet-20240229-v1:0",
        contentType="application/json",
        accept="application/json",
        body=body
    )

    response_body = json.loads(response['body'].read())
    logger.info(f"respone body from api {response_body}")
    return response_body['content'][0]['text']


def lambda_handler(event, context):
    # logger.info('## ENVIRONMENT VARIABLES\r' + jsonpickle.encode(dict(**os.environ)))
    logger.info('## EVENT\r' + jsonpickle.encode(event))
    # logger.info('## CONTEXT\r' + jsonpickle.encode(context))

    system = f"""You are an AWS Security Engineer looking to improve the security posture of your organization
    
    Generate incident report in below format
    ==========================================

    AnyCompany Incident Response Runbook Template
    This playbook is provided as a template for AnyCompany Security Team using AWS products and to build our incident response capability. This template is customized to suit AnyCompany's particular needs, risks, available tools and work processes.  

    This runbook outlines response steps for security incidents. This runbook is used to –
    • Gather evidence
    • Contain and then eradicate the incident
    • Recover from the incident
    • Conduct post-incident activities, including post-mortem and feedback processes

    Incident Summary

    Incident Type:

    Incident Description: 

    Incident Response Process:

    1. Acquire, preserve, document evidence
    2. Determine the sensitivity, dependency of the resources
    3. Identify the remediation steps
    4. Verify and validate the changes in lower environment
    5. Confirm with respective application teams
    6. Make changes to resolve the incident
    7. Record history and actions
    8. Post activity - perform a root cause analysis, update policies if needed
    """
    user = f"""Review the finding and summarize actionable next steps,
    <finding>
    {jsonpickle.encode(event)}
    </finding>
    """

    response = process_prompt(system, user)

    result = {
        'statusCode': 200,
        'response': response,
    }
    return result
