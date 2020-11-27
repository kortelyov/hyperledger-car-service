COUNTER=1
MAX_RETRY=5
PACKAGE_ID=""

CC_RUNTIME_LANGUAGE=golang
CC_SRC_PATH="/opt/gopath/src/chaincode"

export CORE_PEER_TLS_ENABLED=true

ORDERER_CA=${PWD}/fixtures/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
PEER0_AUDITOR_CA=${PWD}/fixtures/organizations/peerOrganizations/auditor.example.com/peers/peer0.auditor.example.com/tls/ca.crt

declare -A MSP
MSP[1]="auditor"
MSP[2]="factory"
MSP[3]="dealer"
MSP[4]="police"
MSP[4]="insurance"

# verify the result of the end-to-end test
verifyResult() {
  if [ $1 -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
    echo
    exit 1
  fi
}

# Set ExampleCom.Admin globals
setOrdererGlobals() {
  CORE_PEER_LOCALMSPID="orderer"
  CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/fixtures/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
  CORE_PEER_MSPCONFIGPATH=${PWD}/fixtures/organizations/ordererOrganizations/example.com/users/Admin@example.com/msp
}

setGlobals() {
  local org=$1
  if [[ "${org}" == "auditor" ]]; then
    CORE_PEER_LOCALMSPID="auditor"
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_AUDITOR_CA
    CORE_PEER_MSPCONFIGPATH=${PWD}/fixtures/organizations/peerOrganizations/auditor.example.com/users/Admin@auditor.example.com/msp
    CORE_PEER_ADDRESS=peer0.auditor.example.com:7051
  elif [[ "${org}" == "factory" ]]; then
    CORE_PEER_LOCALMSPID=factory
    CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/fixtures/organizations/peerOrganizations/factory.example.com/peers/peer0.factory.example.com/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=${PWD}/fixtures/organizations/peerOrganizations/factory.example.com/users/Admin@factory.example.com/msp
    CORE_PEER_ADDRESS=peer0.factory.example.com:8051
  elif [[ "${org}" == "dealer" ]]; then
    CORE_PEER_LOCALMSPID=dealer
    CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/fixtures/organizations/peerOrganizations/dealer.example.com/peers/peer0.dealer.example.com/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=${PWD}/fixtures/organizations/peerOrganizations/dealer.example.com/users/Admin@dealer.example.com/msp
    CORE_PEER_ADDRESS=peer0.dealer.example.com:9051
  elif [[ "${org}" == "police" ]]; then
    CORE_PEER_LOCALMSPID=police
    CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/fixtures/organizations/peerOrganizations/police.example.com/peers/peer0.police.example.com/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=${PWD}/fixtures/organizations/peerOrganizations/police.example.com/users/Admin@police.example.com/msp
    CORE_PEER_ADDRESS=peer0.police.example.com:10051
  elif [[ "${org}" == "insurance" ]]; then
    CORE_PEER_LOCALMSPID=insurance
    CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/fixtures/organizations/peerOrganizations/insurance.example.com/peers/peer0.insurance.example.com/tls/ca.crt
    CORE_PEER_MSPCONFIGPATH=${PWD}/fixtures/organizations/peerOrganizations/insurance.example.com/users/Admin@insurance.example.com/msp
    CORE_PEER_ADDRESS=peer0.insurance.example.com:11051
  else
    echo "${org}"
    echo ">>> error: unknown organization"
  fi
}

parsePeerConnectionParameters() {
  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.${CORE_PEER_LOCALMSPID}.example.com"
    ## Set peer addresses
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="${PEER_CONN_PARMS} --peerAddresses $CORE_PEER_ADDRESS --tlsRootCertFiles ${CORE_PEER_TLS_ROOTCERT_FILE}"
    shift
  done
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}
