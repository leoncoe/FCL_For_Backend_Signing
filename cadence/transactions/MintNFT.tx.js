const MintNFT = `


import NonFungibleToken from  0x631e88ae7f1d7c20
import Dzeko from 0xdd493e0c4aacf384

// This script uses the NFTMinter resource to mint a new NFT
// It must be run with the account that has the minter resource
// stored in Dzeko.MinterStoragePath

transaction(address: Address, name: String, image: String){

    // local variable for storing the minter reference
    let minter: &Dzeko.NFTMinter

    prepare(signer: AuthAccount) {
        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&Dzeko.NFTMinter>(from: Dzeko.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")
    }

    execute {
        // Borrow the recipient's public NFT collection reference
        let receiver = getAccount(address)
            .getCapability(Dzeko.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")

        // Mint the NFT and deposit it to the recipient's collection
        self.minter.mintNFT(
                recipient: receiver,
                name: name,
                image: image 
        )

        log("Minted an NFT")
    }
}

`

module.exports = {MintNFT}