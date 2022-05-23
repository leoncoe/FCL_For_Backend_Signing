// run this script with `node main.js`
// see your transaction at `https://testnet.flowscan.org/transaction/YOUR_TX_ID`

const fcl = require("@onflow/fcl");
const t = require("@onflow/types");
const { MintNFT } = require("./cadence/transactions/MintNFT.tx.js");

const {authorizationFunction, authorizationFunctionProposer} = require("./helpers/authorization.js");

// var description = ""
var image = "https://img.uefa.com/imgml/TP/players/1/2022/324x324/72048.jpg"
var name = "Edin Dzeko"
var address = "0xdd493e0c4aacf384"
// var series = ""
// var quantity = 100
fcl.config()
    .put("accessNode.api", "https://testnet.onflow.org");


const sendTx = async () => {
  const transactionId = await fcl.send([
    fcl.transaction(MintNFT),
    fcl.args([
      fcl.arg(address, t.Address),
      fcl.arg(image, t.String),
      fcl.arg(name, t.String),
    ]),
    fcl.proposer(authorizationFunction),
    fcl.payer(authorizationFunction),
    fcl.authorizations([authorizationFunction]),
    fcl.limit(9999),
  ]).then(fcl.decode);

  console.log(transactionId);
}

sendTx()



