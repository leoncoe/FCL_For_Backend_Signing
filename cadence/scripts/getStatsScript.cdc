import Dzeko from 0xdd493e0c4aacf384
import NonFungibleToken from 0x631e88ae7f1d7c20
 
pub fun main(acct: Address, id: UInt64): &NonFungibleToken.NFT {
  let nftOwner = getAccount(acct)

    // Find the public Receiver capability for their Collection
    let capability = nftOwner.getCapability<&{Dzeko.DzekoCollectionPublic}>(Dzeko.CollectionPublicPath)

    // borrow a reference from the capability
    let receiverRef = capability.borrow()
        ?? panic("Could not borrow the receiver reference")

    // Log the NFTs that they own as an array of IDs
    log(receiverRef.getIDs())
    log(receiverRef.borrowNFT(id: id))

    return receiverRef.borrowNFT(id: id)

    //look into doing a pre-condition before depositing, where if the tokenID exists in the collections array, you cannot put another one
}