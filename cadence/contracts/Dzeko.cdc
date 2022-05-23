import NonFungibleToken from 0x631e88ae7f1d7c20
import StatsInterface from "./StatsInterface.cdc"


// Dzeko.cdc
//
// The Dzeko contract is used to have an NFT hold a seperate type of resource called a 'StatsHolder'
// by the NFT in the Dzeko Contract holding a 'StatsHolder' you are able to add stats that are able to be changed to your NFT, while also being able to be traded

// We also introduce the concept of having functions in resources that are only able to be changed by a specific type of resource that only the admin holds
// this prevents the holder of the NFT from changing the stats but gives the ability to whoever holds the 'MasterKey' resource to access a function that can change stats

// This contract is aimed at gaming developers and looks to show you the power of composability on cadence while creating games.

// a contract named Dzeko
pub contract Dzeko: NonFungibleToken, StatsInterface {

    // create a variable of type dictionary named masterKeys that only the creator of this contract has access to
    access(self) var masterKeys: @{UInt32: MasterKey}

    pub let MasterKeyAdminStoragePath: StoragePath
    pub let MasterKeyAdminPrivatePath: PrivatePath
    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub let StatHolderStoragePath: StoragePath
    pub let StatHolderPrivatePath: PrivatePath

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, name: String)

    // totalSupply
    // The total number of Dzeko that have been minted
    // total number of masterKeys minted
    pub var totalSupply: UInt64
    pub var masterKeySupply: UInt32


//create an NFT with resource interface INFT
    pub resource NFT: NonFungibleToken.INFT{

// dictionary of items, holding the StatHolder resource
        pub let items: @{String: StatsInterface.StatHolder}

// NFT metadata use let because we don't want the id, name, or image to be changable after mint
        pub let id: UInt64
        pub let name: String
        pub let image: String

// arguments to pass in when minting a new NFT, it will be initialized with an empty dict for items
        init(id: UInt64, name: String, image: String,) 
            {
            self.id = id
            self.name= name
            self.image= image
            self.items <- {}
        }

// deposit a token of type StatHolder resource, with a name of the stat
         pub fun deposit(token: @StatsInterface.StatHolder, statName: String) {
            let token <- token

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.items[statName] <- token

            destroy oldToken
        }

        pub fun withdraw(withdrawlKey: String): @StatsInterface.StatHolder {
            let token <- self.items.remove(key: withdrawlKey) ?? panic("missing NFT")

            return <-token
        }

// borrow a reference to the StatHolder resource
        pub fun borrowStatHolder(statName: String): &StatsInterface.StatHolder? {
            if self.items[statName] != nil {
                let ref = &self.items[statName] as &StatsInterface.StatHolder
                return ref
            } else {
                return nil
            }
        }

        destroy() {
            destroy self.items
        }

    }

    // resource interface to let people deposit, get IDs, and borrow references 
    pub resource interface DzekoCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowDzeko(id: UInt64): &Dzeko.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow Dzeko reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of Dzeko NFTs owned by an account
    //
    pub resource Collection: DzekoCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Dzeko.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowDzeko
        // Gets a reference to an NFT in the collection as a Dzeko,
        // exposing all of its fields (including the typeID & rarityID).
        // This is safe as there are no functions that can be called on the Dzeko.
        //
        pub fun borrowDzeko(id: UInt64): &Dzeko.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &Dzeko.NFT
            } else {
                return nil
            }
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

        // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // mintNFT
        // Mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        // pass in arguments of recipient, name, and image string
        pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, name: String, image: String) 
        {
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-create Dzeko.NFT(
                id: Dzeko.totalSupply,
                name: name,
                image: image,
            ))

// emit an event to the blockchain showing what number Dzeko was minted and the name
            emit Minted(
                id: Dzeko.totalSupply,
                name: name
            )

            Dzeko.totalSupply = Dzeko.totalSupply + (1 as UInt64)
        }
    }

// a resource (to be owned by the core nft)
    pub resource StatHolder {

        pub let name: String
        pub var stat: Int

// must pass in a name and a stat as an integer
        init(name: String, stat: Int) {
            self.name = name
            self.stat = stat
        }

        // function writing the stat field in the Statholder resource to the value of the int you give it utilizing a masterkey
        pub fun testingFunc(masterKey: @Dzeko.MasterKey, stat: Int): @Dzeko.MasterKey{
            self.stat = stat
            return <-masterKey
        }
    }

// create a resource called masterkey with an ID (why is it 32?)
    pub resource MasterKey {
      pub let id: UInt32

      init(id: UInt32){
      self.id = id
      }
    }

// resource 
    pub resource MasterKeyAdmin {
// when called, you will create a new masterKey resource with an ID field equal to the number of masterkeys in existence 
// i didnt expose the ability for anyone to create a masterKey, bc i own this resource in my account, so only i can call the function below
        pub fun createMasterKey(): String{
          let newMasterKey <- create MasterKey(id: Dzeko.masterKeySupply)

          Dzeko.masterKeys[newMasterKey.id] <-! newMasterKey

          Dzeko.masterKeySupply = Dzeko.masterKeySupply + 1
          
          return "Success"
        }

        pub fun borrowMasterKey(id: UInt32): &MasterKey {
            return &Dzeko.masterKeys[id] as &MasterKey
        }

        pub fun withdrawKey(withdrawID: UInt32): @MasterKey {
            let token <- Dzeko.masterKeys.remove(key: withdrawID) ?? panic ("missing NFT")
            return <-token
        }

        pub fun depositKey(key: @Dzeko.MasterKey) {
            Dzeko.masterKeys[key.id] <-! key
        }

        pub fun createStatHolder(name: String, statValue: Int): @StatHolder {
            return <-create StatHolder(name: name, stat: statValue)
        }

    }

    pub resource StatHolderAdmin {
        pub fun createStatHolder(name: String, stat: Int): @StatsInterface.StatHolder{
            return <- create StatHolder(name: name, stat: stat)
        } 

    }


    init() {
    // Set our named paths
    self.CollectionStoragePath = /storage/DzekoCollections
    self.CollectionPublicPath = /public/DzekoCollections
    self.MinterStoragePath = /storage/DzekoMinters
    self.MasterKeyAdminStoragePath = /storage/MasterKeyAdminStorage
    self.MasterKeyAdminPrivatePath = /private/MasterKeyAdminPrivate
    self.StatHolderPrivatePath = /private/StatsHolderPrivate
    self.StatHolderStoragePath = /storage/StatsHolderStorage

    // Initialize the total supply
    self.totalSupply = 0
    self.masterKeySupply = 0

    // Put Admin in storage
    self.account.save(<-create MasterKeyAdmin(), to: self.MasterKeyAdminStoragePath)

    self.account.link<&Dzeko.MasterKeyAdmin>(
        self.MasterKeyAdminPrivatePath,
        target: self.MasterKeyAdminStoragePath
    ) ?? panic("Could not get a capability to the admin")

    // Create a Minter resource and save it to storage
    let minter <- create NFTMinter()
    self.account.save(<-minter, to: self.MinterStoragePath)

    emit ContractInitialized()

    self.masterKeys <- {}
    }
}
