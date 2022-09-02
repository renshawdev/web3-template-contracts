import hre from 'hardhat'
import { passArgs } from './config'

const name = "ERC721AMinter"

async function main() {
  const factory = await hre.ethers.getContractFactory(name);
  const contract = await factory.deploy(passArgs)
  await contract.deployed()

  console.log(`${name} deployed to:`, contract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
