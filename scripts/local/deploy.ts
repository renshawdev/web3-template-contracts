import hre from 'hardhat'
import { passArgs } from './config'

const contractName = "ERC721AMinter"

const [
  name,
  symbol,
  hiddenMetadataURI,
  developer,
  maxSupply
] = passArgs

async function main() {
  const factory = await hre.ethers.getContractFactory(contractName);
  const contract = await factory.deploy(name, symbol, hiddenMetadataURI, developer, maxSupply)
  await contract.deployed()

  console.log(`${contractName} deployed to:`, contract.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
