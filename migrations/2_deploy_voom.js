const Voom = artifacts.require('./Voom.sol')
const TokenX = artifacts.require('./libraries/TokenX.sol')


module.exports = async function (deployer) {
    let status = false
    let addr = process.env.CHEF
    if( parseInt(process.env.TEST) === 1 ){
        status = true
        await deployer.deploy(TokenX)
        const tokenX = await TokenX.deployed()
        addr = tokenX.address
    }
    await deployer.deploy(Voom, process.env.CHEF, process.env.DEV_COMMISSIONS_1, process.env.DEV_COMMISSIONS_2, status, addr, web3.utils.toWei("800000"), web3.utils.toWei("1000000"))
}