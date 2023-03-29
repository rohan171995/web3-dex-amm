// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  const BBL = await hre.ethers.getContractFactory("BigBashLeague");
  const bbl = await BBL.deploy(100000);

  await bbl.deployed();

  console.log(
    `BBL is successfully deployed to ${bbl.address}`
  );

  const IPL = await hre.ethers.getContractFactory("IndianPremierLeague");
  const ipl = await IPL.deploy(100000);

  await ipl.deployed();

  console.log(
    `ipl is successfully deployed to ${ipl.address}`
  );

  const DXCSwap = await hre.ethers.getContractFactory("DCXSwap");
  const dcxSwap = await DXCSwap.deploy(ipl.address, bbl.address);

  await dcxSwap.deployed();

  console.log(
    `DXCSwap is successfully deployed to ${dcxSwap.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
