#!/bin/bash

echo "=> Starting Applivery iOS Deploy"

THIS_SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function echoStatusFailed {
  envman add --key APPLIVERY_DEPLOY_STATUS --value "failed"
  echo
  echo 'APPLIVERY_DEPLOY_STATUS: "failed"'
  echo " --------------"
}

############# VALIDATIONS ##############

# IPA
if [ ! -f "${ipa_path}" ] ; then
  echo "# Error"
  echo "* No IPA found to deploy. Specified path was: ${ipa_path}"
  echoStatusFailed
  exit 1
fi

# APPLIVERY API TOKEN
if [ -z "${api_token}" ] ; then
  echo "# Error"
  echo '* No APPLIVERY_API_TOKEN provided as environment variable. Terminating...'
  echoStatusFailed
  exit 1
fi

# APPLIVER APP ID
if [ -z "${app_id}" ] ; then
  echo "# Error"
  echo '* No APPLIVERY_APP_ID provided as environment variable. Terminating...'
  echoStatusFailed
  exit 1
fi

############# DEFINITIONS ##############

bitrise_build_number="${BITRISE_BUILD_NUMBER}"
git_repository_url="${GIT_REPOSITORY_URL}"
bitrise_app_url="${BITRISE_APP_URL}"
bitrise_build_url="${BITRISE_BUILD_URL}"
bitrise_build_trigger_timestamp="${BITRISE_BUILD_TRIGGER_TIMESTAMP}"
bitrise_git_branch="${BITRISE_GIT_BRANCH}"
bitrise_git_tag="${BITRISE_GIT_TAG}"
bitrise_git_commit="${BITRISE_GIT_COMMIT}"
bitrise_git_message="${BITRISE_GIT_MESSAGE}"
bitrise_provision_url="${BITRISE_PROVISION_URL}"
bitrise_certificate_url="${BITRISE_CERTIFICATE_URL}"

echo
echo "========== CONFIGS =========="
echo "* api_token: ********"
echo "* app_id: ${app_id}"
echo "* version_name: ${version_name}"
echo "* notes: ${notes}"
echo "* notify: ${notify}"
echo "* os: ${os}"
echo "* tags: ${tags}"
echo "* ipa_path: ${ipa_path}"
echo "***** Other variables *****"
echo "* bitrise_build_number: ${bitrise_build_number}"
echo "* git_repository_url: ${git_repository_url}"
echo "* bitrise_app_url: ${bitrise_app_url}"
echo "* bitrise_build_url: ${bitrise_build_url}"
echo "* bitrise_build_trigger_timestamp: ${bitrise_build_trigger_timestamp}"
echo "* bitrise_git_branch: ${bitrise_git_branch}"
echo "* bitrise_git_tag: ${bitrise_git_tag}"
echo "* bitrise_git_commit: ${bitrise_git_commit}"
echo "* bitrise_git_message: ${bitrise_git_message}"
echo "* bitrise_provision_url: ${bitrise_provision_url}"
echo "* bitrise_certificate_url: ${bitrise_certificate_url}"
echo "***** BITRISE XCODE TEST *****"
echo "* BITRISE_XCODE_RAW_TEST_RESULT_TEXT_PATH: ${BITRISE_XCODE_RAW_TEST_RESULT_TEXT_PATH}"
echo

###########################

curl_cmd="curl --fail"
curl_cmd="$curl_cmd -H \"Authorization: ${api_token}\""
curl_cmd="$curl_cmd -F \"app=${app_id}\""
curl_cmd="$curl_cmd -F \"versionName=${version_name}\""
curl_cmd="$curl_cmd -F \"notes=${notes}\""
curl_cmd="$curl_cmd -F \"notify=${notify}\""
curl_cmd="$curl_cmd -F \"os=ios\""
curl_cmd="$curl_cmd -F \"deployer=bitrise\""
curl_cmd="$curl_cmd -F \"tags=${tags}\""
curl_cmd="$curl_cmd -F \"package=@${ipa_path}\""
curl_cmd="$curl_cmd -F \"bitrise_build_number=${bitrise_build_number}\""
curl_cmd="$curl_cmd -F \"git_repository_url=${git_repository_url}\""
curl_cmd="$curl_cmd -F \"bitrise_app_url=${bitrise_app_url}\""
curl_cmd="$curl_cmd -F \"bitrise_build_url=${bitrise_build_url}\""
curl_cmd="$curl_cmd -F \"bitrise_build_trigger_timestamp=${bitrise_build_trigger_timestamp}\""
curl_cmd="$curl_cmd -F \"bitrise_git_branch=${bitrise_git_branch}\""
curl_cmd="$curl_cmd -F \"bitrise_git_tag=${bitrise_git_tag}\""
curl_cmd="$curl_cmd -F \"bitrise_git_commit=${bitrise_git_commit}\""
curl_cmd="$curl_cmd -F \"bitrise_git_message=${bitrise_git_message}\""
curl_cmd="$curl_cmd -F \"bitrise_provision_url=${bitrise_provision_url}\""
curl_cmd="$curl_cmd -F \"bitrise_certificate_url=${bitrise_certificate_url}\""
# BITRISE TESTS
if [ ! -f "${BITRISE_XCODE_RAW_TEST_RESULT_TEXT_PATH}" ] ; then
  curl_cmd="$curl_cmd -F \"bitrise_xcode_raw_test_result_text_path=${BITRISE_XCODE_RAW_TEST_RESULT_TEXT_PATH}\""
fi
curl_cmd="$curl_cmd https://dashboard.applivery.com/api/builds"

echo
echo "=> Curl:"
echo '$' $curl_cmd
echo

json=$(eval $curl_cmd)
curl_res=$?

echo
echo "========== RESULT =========="
echo " * cURL command exit code: ${curl_res}"
echo " * JSON response: ${json}"
echo "============================"
echo

if [ ${curl_res} -ne 0 ] ; then
  echo "# Error"
  echo '* cURL command exit code not zero!'
  echoStatusFailed
  exit 1
fi

# error handling
if [[ ${json} ]] ; then
  errors=`ruby "${THIS_SCRIPTDIR}/steps-utils-jsonval/parse_json.rb" \
  --json-string="${json}" \
  --prop=error`
  parse_res=$?
  if [ ${parse_res} -ne 0 ] ; then
     errors="Failed to parse the response JSON"
  fi
else
  errors="No valid JSON result from request."
fi

if [[ ${errors} ]]; then
  echo "# Error"
  echo "* ${errors}"
  echoStatusFailed
  exit 1
fi

# everything is OK

envman add --key "APPLIVERY_DEPLOY_STATUS" --value "success"


# final results
echo "* Deploy Result: Success"

exit 0
