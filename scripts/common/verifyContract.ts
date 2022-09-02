import hre from 'hardhat'

const verifyContract = async (address: string, constructorArguments: any[]) => {
    await hre.run("verify:verify", { address, constructorArguments });
}

export default verifyContract
