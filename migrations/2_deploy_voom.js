const Voom = artifacts.require('./Voom.sol')

module.exports = async function (deployer) {
    await deployer.deploy(Voom, process.env.CHEF, process.env.DEV_COMMISSIONS_1, process.env.DEV_COMMISSIONS_2)
}