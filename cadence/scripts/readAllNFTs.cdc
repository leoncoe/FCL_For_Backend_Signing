import Dzeko from 0xdd493e0c4aacf384

// read all NFTs in this collection

pub fun main(address: Address): AnyStruct {    
    let account = getAccount(address)

    let nftRef = account
            .getCapability(Dzeko.CollectionPublicPath)
            .borrow<&{Dzeko.DzekoCollectionPublic}>()
        ?? panic("Could not borrow a reference to the collection")

    let nft = nftRef.getIDs()

    var i = 0

    while i < nft.length {
    let nftMetadata = nftRef.borrowDzeko(id: nft[i])
    i = i + 1

    log(nftMetadata)
    }
    return nft
}