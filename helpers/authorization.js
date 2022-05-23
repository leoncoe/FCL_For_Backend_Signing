const fcl = require("@onflow/fcl");
const { SHA3 } = require("sha3");

var EC = require('elliptic').ec;
const ec = new EC('p256');

const ADDRESS = "0xdd493e0c4aacf384";
const PRIVATE_KEY = "b4d8f86f5b7a145b3f2c30c3e21b8d02d68b5c3d4a1bfa38e7c197c158dc4dfa";
const KEY_ID = 0;
const NUMBER_OF_KEYS_IN_ACCOUNT = 20
const sign = (message) => {
    const key = ec.keyFromPrivate(Buffer.from(PRIVATE_KEY, "hex"));
    const sig = key.sign(hash(message)); // hashMsgHex -> hash
    const n = 32;
    const r = sig.r.toArrayLike(Buffer, "be", n);
    const s = sig.s.toArrayLike(Buffer, "be", n);
    return Buffer.concat([r, s]).toString("hex");
}

const hash = (message) => {
    const sha = new SHA3(256);
    sha.update(Buffer.from(message, "hex"));
    return sha.digest();
}

const authorizationFunction = async (account) => {
    // authorization function need to return an account
    return {
        ...account, // bunch of defaults in here, we want to overload some of them though
        tempId: `${ADDRESS}-${KEY_ID}`, // tempIds are more of an advanced topic, for 99% of the times where you know the address and keyId you will want it to be a unique string per that address and keyId
        addr: fcl.sansPrefix(ADDRESS), // the address of the signatory, currently it needs to be without a prefix right now
        keyId: Number(KEY_ID), // this is the keyId for the accounts registered key that will be used to sign, make extra sure this is a number and not a string
        signingFunction: async signable => {
            // Singing functions are passed a signable and need to return a composite signature
            // signable.message is a hex string of what needs to be signed.
            return {
                addr: fcl.withPrefix(ADDRESS), // needs to be the same as the account.addr but this time with a prefix, eventually they will both be with a prefix
                keyId: Number(KEY_ID), // needs to be the same as account.keyId, once again make sure its a number and not a string
                signature: sign(signable.message), // this needs to be a hex string of the signature, where signable.message is the hex value that needs to be signed
            }
        }
    }
}

var KEY_ID_ITERABLE = 0;
var loop_count = 0
const authorizationFunctionProposer = async (account) => {
    if (KEY_ID_ITERABLE >= NUMBER_OF_KEYS_IN_ACCOUNT) {
        KEY_ID_ITERABLE = 0;
    } else {
        if(loop_count % 2 == 0){
            KEY_ID_ITERABLE++;
            loop_count++
        } else{
            loop_count++
        }
    }

        return {
            ...account, // bunch of defaults in here, we want to overload some of them though
            tempId: `${ADDRESS}-${KEY_ID_ITERABLE}`, // tempIds are more of an advanced topic, for 99% of the times where you know the address and keyId you will want it to be a unique string per that address and keyId
            addr: fcl.sansPrefix(ADDRESS), // the address of the signatory, currently it needs to be without a prefix right now
            keyId: Number(KEY_ID_ITERABLE), // this is the keyId for the accounts registered key that will be used to sign, make extra sure this is a number and not a string
            signingFunction: async signable => {
                // Singing functions are passed a signable and need to return a composite signature
                // signable.message is a hex string of what needs to be signed.
                return {
                    addr: fcl.withPrefix(ADDRESS), // needs to be the same as the account.addr but this time with a prefix, eventually they will both be with a prefix
                    keyId: Number(KEY_ID_ITERABLE), // needs to be the same as account.keyId, once again make sure its a number and not a string
                    signature: sign(signable.message), // this needs to be a hex string of the signature, where signable.message is the hex value that needs to be signed
                }
            }
        }
       
}

module.exports = {
    authorizationFunction,
    authorizationFunctionProposer
}