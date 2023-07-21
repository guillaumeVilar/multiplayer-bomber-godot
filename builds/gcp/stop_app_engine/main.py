# Cloud function to stop all the versions of a specified service. 
# API reference is here: 
# https://cloud.google.com/appengine/docs/admin-api/reference/rest

import os
from googleapiclient import discovery
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from google.auth import compute_engine
import functions_framework

PROJECT_ID = "just-amp-373710"
SERVICE_ID = "default"

def get_app_engine_credentials():
    """
    Get credentials to access the App Engine Admin API.
    This function can be used to fetch the credentials in Google Cloud Functions.
    """
    # Detect the environment and choose the appropriate method for getting credentials
    if 'GAE_ENV' in os.environ:
        credentials, _ = google.auth.default()
        return credentials
    elif 'GOOGLE_APPLICATION_CREDENTIALS' in os.environ:
        credentials = Credentials.from_authorized_user_file(
            os.environ['GOOGLE_APPLICATION_CREDENTIALS']
        )
        return credentials
    else:
        credentials = compute_engine.Credentials()
        credentials.refresh(Request())
        return credentials

def get_versions_in_appengine_service(service):
    versions = service.apps().services().versions().list(
        appsId=PROJECT_ID,
        servicesId=SERVICE_ID,
        view="BASIC"
    ).execute()
    return [ version['id'] for version in versions['versions'] ]


@functions_framework.http
def stop_appengine_service(request):
    """
    Cloud Function to start an App Engine service.
    Triggered via HTTP request.
    """

    # Authenticate using the App Engine Admin API scope
    credentials = get_app_engine_credentials()
    service = discovery.build('appengine', 'v1', credentials=credentials)
    service_versions = get_versions_in_appengine_service(service)

    for version in service_versions:
        # Start the App Engine service
        service.apps().services().versions().patch(
            appsId=PROJECT_ID,
            servicesId=SERVICE_ID,
            versionsId=version,
            updateMask='servingStatus',
            body={'servingStatus': "STOPPED"}
        ).execute()

    return f'Stopped App Engine service: {SERVICE_ID} with versions: {service_versions}'
