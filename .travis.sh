set -e

REGEX_SLUG="(.+)/(.+)"
[[ $TRAVIS_REPO_SLUG =~ $REGEX_SLUG ]]
REPO_NAME=${BASH_REMATCH[2]}

zipName=""
gmaName=""

if [ ! -z "$TRAVIS_TAG" ]
then
	export TAGGED_RELEASE=true

	zipName="${REPO_NAME}-${TRAVIS_TAG}"
	gmaName="${REPO_NAME}"
else
	export TAGGED_RELEASE=false
fi

export DEST_ARCHIVE="$(echo ${zipName} | tr '[:upper:]' '[:lower:]')"
export DEST_GMA="$(echo ${gmaName} | tr '[:upper:]' '[:lower:]')"

gulp build
gulp travisPostBuild

mv ./dest/gamemode.zip ./dest/$DEST_ARCHIVE.zip
./gmad create -folder dest -out dest/$DEST_GMA.gma
