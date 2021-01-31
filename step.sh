#!/bin/bash

echo "=> Starting Applivery v3 iOS Deploy"

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
if [ -z "${appToken}" ] ; then
  echo "# Error"
  echo '* No App Token provided as environment variable. Terminating...'
  echoStatusFailed
  exit 1
fi

############# DEFINITIONS ##############

buildNumber="${BITRISE_BUILD_NUMBER}"
repositoryUrl="${GIT_REPOSITORY_URL}"
ciUrl="${BITRISE_APP_URL}"
buildUrl="${BITRISE_BUILD_URL}"
triggerTimestamp="${BITRISE_BUILD_TRIGGER_TIMESTAMP}"
branch="${BITRISE_GIT_BRANCH}"
tag="${BITRISE_GIT_TAG}"
commit="${BITRISE_GIT_COMMIT}"
commitMessage="${BITRISE_GIT_MESSAGE}"
provisionUrl="${BITRISE_PROVISION_URL}"
app_path="${BITRISE_APP_DIR_PATH}"

echo
echo "========== CONFIGURATION =========="
echo "* appToken: *****************"
echo "* app_id: deprecated"
echo "* version_name: ${versionName}"
echo "* changelog: ${changelog}"
echo "* notifyCollaborators: ${notifyCollaborators}"
echo "* notifyEmployees: ${notifyEmployees}"
echo "* notifyMessage: ${notifyMessage}"
echo "* autoremove: deprecated"
echo "* os: deprecated"
echo "* tags: ${tags}"
echo "* ipa_path: ${ipa_path}"
echo "* app_path: ${app_path}"
echo
echo "========== DEPLOYMENT VALUES =========="
echo "* commitMessage: ${commitMessage}"
echo "* commit: ${commit}"
echo "* branch: ${branch}"
echo "* tag: ${tag}"
echo "* triggerTimestamp: ${triggerTimestamp}"
echo "* buildUrl: ${buildUrl}"
echo "* ciUrl: ${ciUrl}"
echo "* repositoryUrl: ${repositoryUrl}"
echo "* buildNumber: ${buildNumber}"
echo "* provisionUrl: ${provisionUrl}"


echo
############# Generate Zip ###############
zip -r "/tmp/app.zip" "${app_path}"
tmpAppPath="/tmp/app.zip"
echo "* tmpAppPath: ${tmpAppPath}"


############# GENERATE CURL ##############

# Add Cmain params
curl_cmd="curl --fail"
curl_cmd="$curl_cmd -H \"Authorization: bearer ${appToken}\""
curl_cmd="$curl_cmd -F \"versionName=${versionName}\""
curl_cmd="$curl_cmd -F \"changelog=${changelog}\""
curl_cmd="$curl_cmd -F \"notifyCollaborators=${notifyCollaborators}\""
curl_cmd="$curl_cmd -F \"notifyEmployees=${notifyEmployees}\""
curl_cmd="$curl_cmd -F \"tags=${tags}\""
curl_cmd="$curl_cmd -F \"filter=${filter}\""

curl_cmd="$curl_cmd -F \"build=@${ipa_path}\""
curl_cmd="$curl_cmd -F \"simulatorBuild=@${tmpAppPath}\""
curl_cmd="$curl_cmd -F \"deployer.name=bitrise\""
curl_cmd="$curl_cmd -F \"deployer.info.commitMessage=${commitMessage}\""
curl_cmd="$curl_cmd -F \"deployer.info.commit=${commit}\""
curl_cmd="$curl_cmd -F \"deployer.info.branch=${branch}\""
curl_cmd="$curl_cmd -F \"deployer.info.tag=${tag}\""
curl_cmd="$curl_cmd -F \"deployer.info.triggerTimestamp=${triggerTimestamp}\""
curl_cmd="$curl_cmd -F \"deployer.info.buildUrl=${buildUrl}\""
curl_cmd="$curl_cmd -F \"deployer.info.ciUrl=${ciUrl}\""
curl_cmd="$curl_cmd -F \"deployer.info.repositoryUrl=${repositoryUrl}\""
curl_cmd="$curl_cmd -F \"deployer.info.buildNumber=${buildNumber}\""

# Add Codesigning conditionally
if [ "${uploadCodeSigning}" = true ] ; then
  curl_cmd="$curl_cmd -F \"deployer.info.provisionUrl=${provisionUrl}\""
  curl_cmd="$curl_cmd -F \"deployer.info.certificateUrl=${certificateUrl}\""
  curl_cmd="$curl_cmd -F \"deployer.info.certificatePassphrase=${certificatePassphrase}\""
fi

# Add Applivery API URL
curl_cmd="$curl_cmd https://api.applivery.io/v1/integrations/builds"

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
