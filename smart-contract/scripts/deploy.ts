import hre from "hardhat";

async function main() {
    await hre.run('compile');

    const BasedLinktree = await hre.ethers.getContractFactory("BasedLinktree");
    const basedLinktree = await BasedLinktree.deploy();
    await basedLinktree.waitForDeployment();

    console.log("BasedLinktree Contract Address", await basedLinktree.getAddress())
}

main().then( () => process.exit(0))
.catch( (error) => {
    console.error(error);
    process.exit(1);
});