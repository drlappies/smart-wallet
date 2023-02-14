const SmartWallet = artifacts.require("SmartWallet");

contract("SmartWallet", async (accounts) => {
  let smartWallet;

  beforeEach(async () => {
    smartWallet = await SmartWallet.deployed();
  });

  describe("")
});
