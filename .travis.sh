set -e

REGEX_SLUG="(.+)/(.+)"
[[ $TRAVIS_REPO_SLUG =~ $REGEX_SLUG ]]
REPO_NAME=${BASH_REMATCH[2]}

releaseName=""

if [ ! -z "$TRAVIS_TAG" ]
then
	export TAGGED_RELEASE=true

	releaseName="${REPO_NAME}-${TRAVIS_TAG}"
else
	export TAGGED_RELEASE=false
fi

export DEST_ARCHIVE="$(echo ${releaseName} | tr '[:upper:]' '[:lower:]')"

gulp build
gulp travisPostBuild

mv ./dest/gamemode.zip ./dest/$DEST_ARCHIVE.zip
./gmad create -folder dest -out dest/$DEST_ARCHIVE.gma

echo "Release = ${releaseName}"
echo "Tagged release = ${TAGGED_RELEASE}"
