const SmartWallet = artifacts.require("SmartWallet");

module.exports = function (deployer) {
  deployer.deploy(SmartWallet);
};
