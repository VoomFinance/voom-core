const Members = artifacts.require('./Members.sol')

module.exports = async function (deployer) {
    await deployer.deploy(Members)
    const members = await Members.deployed()
    await members.addMember(process.env.DEV_ADDRESS, process.env.DEV_ADDRESS)
}