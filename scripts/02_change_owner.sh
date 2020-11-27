#!/bin/bash

DELAY="$1"
TIMEOUT="$2"
VERBOSE="$3"
MAX_RETRY="$4"
# shellcheck disable=SC2223
: ${DELAY:="3"}
# shellcheck disable=SC2223
: ${TIMEOUT:="10"}
# shellcheck disable=SC2223
: ${VERBOSE:="false"}
# shellcheck disable=SC2223
: ${MAX_RETRY:="false"}

# import utils
. scripts/utils.sh

parsePeerConnectionParameters() {
  PEER_CONN_PARAMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.${CORE_PEER_LOCALMSPID}.example.com"
    ## Set peer addresses
    PEERS="$PEERS $PEER"
    PEER_CONN_PARAMS="${PEER_CONN_PARAMS} --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles ${CORE_PEER_TLS_ROOTCERT_FILE}"
    shift
  done
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

chaincodeInvoke() {
  local channel=$1
  local name=$2
  local org=$3
  local args=$4
  shift 4

  parsePeerConnectionParameters $@

  setGlobals "${org}"

  set -x
  peer chaincode invoke -o orderer.example.com:7050 --tls --cafile "${ORDERER_CA}" --channelID "${channel}" --name "${name}" -c "${args}" $PEER_CONN_PARAMS >&log.txt
  res=$?
  set +x
  cat log.txt

  verifyResult $res "invoke execution on ${CORE_PEER_ADDRESS} failed "
  echo ">>> invoke transaction successful on ${CORE_PEER_ADDRESS} on channel '${channel}'"
}

# channel_name chaincode_name org args @peers
chaincodeInvoke global history police '{"function":"ChangeOwner","Args":["2G1WF52K959355243", "3gHYu7Adjm"]}' auditor factory dealer police insurance

echo

exit 0
