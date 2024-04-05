const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("NFTMarketModule", (m) => {
  const NFTMarket = m.contract("NFTMarket");

  return { NFTMarket };
});
