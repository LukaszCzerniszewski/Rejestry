#!/bin/bash
export FABRIC_CFG_PATH=${PWD}/configtx
export PATH=$PATH:./bin
COMPOSE_FILE_BASE=docker/docker-compose-test-net.yaml
IMAGETAG="latest"
VERBOSE="false"
RED='\033[0;31m'
NC='\033[0m' # No Color
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
# errorln echos i red color
function errorln() {
  println "${C_RED}${1}${C_RESET}"
}

# successln echos in green color
function successln() {
  println "${C_GREEN}${1}${C_RESET}"
}

# infoln echos in blue color
function infoln() {
  println "${C_BLUE}${1}${C_RESET}"
}

# warnln echos in yellow color
function warnln() {
  println "${C_YELLOW}${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
  errorln "$1"
  exit 1
}

# println echos string
function println() {
  echo -e "$1"
}

function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    infoln "No containers available for deletion"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    infoln "No images available for deletion"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

docker-compose -f $COMPOSE_FILE_BASE down --volumes --remove-orphans
#Cleanup the chaincode containers
clearContainers
#Cleanup images
removeUnwantedImages
docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'
# remove channel and script artifacts
docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt *.tar.gz'

if [ $1 = "up" ];then
 # remove old directories
 if [ -d "organizations/peerOrganizations" ]; then
     rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
 fi
 
 # generate certificates
 which cryptogen
 if [ "$?" -ne 0 ]; then
   fatalln "cryptogen tool not found. exiting"
 fi
 infoln "Generating certificates using cryptogen tool"
 
 infoln "Creating Org1 Identities"
 set -x
 cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output="organizations"
 res=$?
 { set +x; } 2>/dev/null
 if [ $res -ne 0 ]; then
   fatalln "Failed to generate certificates..."
 fi
 
 infoln "Creating Org2 Identities"
 set -x
 cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output="organizations"
 res=$?
 { set +x; } 2>/dev/null
 if [ $res -ne 0 ]; then
   fatalln "Failed to generate certificates..."
 fi
 
 infoln "Creating Orderer Org Identities"
 set -x
 cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
 res=$?
 { set +x; } 2>/dev/null
 if [ $res -ne 0 ]; then
   fatalln "Failed to generate certificates..."
 fi
 
 infoln "Generating CCP files for Org1 and Org2"
 ./organizations/ccp-generate.sh
 
 #Create consortium
 
 which configtxgen
 if [ "$?" -ne 0 ]; then
   fatalln "configtxgen tool not found."
 fi
 infoln "Generating Orderer Genesis block"
 # Note: For some unknown reason (at least for now) the block file can't be
 # named orderer.genesis.block or the orderer will fail to launch!
 set -x
 configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
 res=$?
 { set +x; } 2>/dev/null
 if [ $res -ne 0 ]; then
   fatalln "Failed to generate orderer genesis block..."
 fi
 
 #Run docker containers
 COMPOSE_FILES="-f ${COMPOSE_FILE_BASE}"
 IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1
 docker ps -a
 if [ $? -ne 0 ]; then
   fatalln "Unable to start network"
 fi


 echo "${YELLOW}=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#=#${NC}"
 scripts/createChannel.sh example 3 5 $VERBOSE
 echo "${RED}===================================================================================================================${NC}"
 scripts/deployCC.sh example Example ../Example go 1.0 1 "" "" "" 3 3 false
 echo "${RED}===================================================================================================================${NC}"
fi
