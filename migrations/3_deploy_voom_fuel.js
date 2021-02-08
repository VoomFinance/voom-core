const VoomFuel = artifacts.require('./VoomFuel.sol')
const Members = artifacts.require('./Members.sol')

module.exports = async function (deployer) {
    const members = await Members.deployed()
    await deployer.deploy(VoomFuel, members.address, process.env.DEV_ADDRESS, process.env.CHEF)
}