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

bitrise_build_number="${BITRISE_BUILD_NUMBER}"
git_repository_url="${GIT_REPOSITORY_URL}"
bitrise_app_url="${BITRISE_APP_URL}"
bitrise_build_url="${BITRISE_BUILD_URL}"
bitrise_build_trigger_timestamp="${BITRISE_BUILD_TRIGGER_TIMESTAMP}"
bitrise_git_branch="${BITRISE_GIT_BRANCH}"
bitrise_git_tag="${BITRISE_GIT_TAG}"
bitrise_git_commit="${BITRISE_GIT_COMMIT}"
bitrise_git_message="${BITRISE_GIT_MESSAGE}"

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


echo

###########################

curl_cmd="curl --fail"
curl_cmd="$curl_cmd -H \"Authorization: bearer ${appToken}\""
curl_cmd="$curl_cmd -F \"versionName=${versionName}\""
curl_cmd="$curl_cmd -F \"changelog=${changelog}\""
curl_cmd="$curl_cmd -F \"notifyCollaborators=${notifyCollaborators}\""
curl_cmd="$curl_cmd -F \"notifyEmployees=${notifyEmployees}\""
curl_cmd="$curl_cmd -F \"os=android\""
curl_cmd="$curl_cmd -F \"tags=${tags}\""
curl_cmd="$curl_cmd -F \"build=@${ipa_path}\""
curl_cmd="$curl_cmd -F \"deployer=bitrise\""
curl_cmd="$curl_cmd -F \"commitMessage=${commitMessage}\""
curl_cmd="$curl_cmd -F \"commit=${commit}\""
curl_cmd="$curl_cmd -F \"branch=${branch}\""
curl_cmd="$curl_cmd -F \"tag=${tag}\""
curl_cmd="$curl_cmd -F \"triggerTimestamp=${triggerTimestamp}\""
curl_cmd="$curl_cmd -F \"buildUrl=${buildUrl}\""
curl_cmd="$curl_cmd -F \"ciUrl=${ciUrl}\""
curl_cmd="$curl_cmd -F \"repositoryUrl=${repositoryUrl}\""
curl_cmd="$curl_cmd -F \"buildNumber=${buildNumber}\""
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
