pub contract interface StatsInterface {

//a resource called StatHolder that holds the name of the stat and the integer value of the stat
  pub resource StatHolder {

    pub let name: String
    pub var stat: Int

  }

//an admin resource that allows you to create a StatHolder resource
  pub resource StatHolderAdmin {

    pub fun createStatHolder(name: String, stat: Int): @StatHolder 

  }
}