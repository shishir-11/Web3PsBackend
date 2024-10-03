const hre = require("hardhat")
async function main() {
    // Get the contract factory
    const CustomDex = await hre.ethers.getContractFactory("DexAmoy");
  
    // Deploy the contract
    const dex = await CustomDex.deploy(); // This returns a contract instance
    // Wait for the contract to be deployed
    // await dex.deployed(); // Ensure the contract is fully deployed
    await dex.waitForDeployment();
    const addressDex = await dex.getAddress();
    
    const receiverContract = await hre.ethers.getContractFactory("ReceiverAmoy");
    const receiver = await receiverContract.deploy("0x9C32fCB86BF0f4a1A8921a9Fe46de3198bb884B2",addressDex);
    const addressReceiver = await receiver.getAddress();
    const setReceiverSelf = dex.getFunction("setReceiverSelf");
    const getSenderAddress  = dex.getFunction("getSenderAddress");
    const senderAddress = await getSenderAddress(); 
    setReceiverSelf(addressReceiver);
    console.log("DEX deployed to:", addressDex); // Now it should correctly show the address
    console.log("receiver deployed to:", addressReceiver);
    console.log("sender delpoyed to: ", senderAddress);
  }
  
  main()
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  