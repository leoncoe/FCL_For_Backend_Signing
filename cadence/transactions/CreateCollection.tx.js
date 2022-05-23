const CreateCollection = `

import NonFungibleToken from 0x631e88ae7f1d7c20
import Dzeko from 0xdd493e0c4aacf384

// This transaction is what an account would run
// to set itself up to receive NFTs

transaction {

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        if signer.borrow<&Dzeko.Collection>(from: Dzeko.CollectionStoragePath) != nil {
            return
        }

        // Create a new empty collection
        // accessing a public function exposed in the contract, moving that resource created into the collection variable
        let collection <- Dzeko.createEmptyCollection()

        // save it to the account's storage path
        signer.save(<-collection, to: Dzeko.CollectionStoragePath)

        // create a public capability for the collection. exposing interfaces to the public
        signer.link<&{NonFungibleToken.CollectionPublic, Dzeko.DzekoCollectionPublic}>(
            Dzeko.CollectionPublicPath,
            target: Dzeko.CollectionStoragePath
        )
    }

    execute {
      log("Setup account")
    }
}

`

module.exports = {CreateCollection}