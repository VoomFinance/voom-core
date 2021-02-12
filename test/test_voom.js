  
const assert = require('assert');
const BigNumber = require('bignumber.js')
const Voom = artifacts.require('./Voom.sol')
const TokenX = artifacts.require('./libraries/TokenX.sol')

contract('Voom', ([owner]) => {

    it('Should deploy smart contract', async () => {
        const voom = await Voom.deployed()
        assert(voom.address !== '')
    })

    it('Send tokensX to 30 addresses', async () => {
        const tokenX = await TokenX.deployed()
        const accounts = await web3.eth.getAccounts()
        if (accounts.length >= 32) {
            for (let i = 1; i <= 32; i++) {
                await tokenX.transfer(accounts[i], new BigNumber((10000 * (10 ** 18))))
            }
            const balance_account_1 = await tokenX.balanceOf.call(accounts[1])
            const balance_account_30 = await tokenX.balanceOf.call(accounts[30])            
            assert(balance_account_1.toString() == '10000000000000000000000' && balance_account_30.toString() == '10000000000000000000000')
        } else {
            assert(false)
        }
    })

    it('Approve tokensX to 30-address voom', async () => {
        const tokenX = await TokenX.deployed()
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        if (accounts.length >= 32) {
            const balance_account_1 = await tokenX.balanceOf.call(accounts[1])
            const balance_account_30 = await tokenX.balanceOf.call(accounts[30])
            if (balance_account_1.toString() == '10000000000000000000000' && balance_account_30.toString() == '10000000000000000000000') {
                for (let i = 1; i <= 32; i++) {
                    await tokenX.approve(voom.address, new BigNumber((10000 * (10 ** 18))), { from: accounts[i] })
                }
                assert(true)
            } else {
                assert(false)
            }
        } else {
            assert(false)
        }
    })

    it('Deposit tokensX to 30-address voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        if (accounts.length >= 30) {
            const voom_last = await voom.vooms.call(accounts[0])
            const tokens = new BigNumber((100 * (10 ** 18)))
            for (let i = 1; i <= 30; i++) {
                await voom.deposit(tokens, accounts[(i-1)], { from: accounts[i] })
            }
            const voom_new = await voom.vooms.call(accounts[0])
            assert(voom_new.amountBonus.toString() == '20000000000000000000')
        } else {
            assert(false)
        }
    })

    it('Change daily', async () => {
        const voom = await Voom.deployed()
        await voom.setDaily('100000000000000000000')
        const check = await voom.daily.call()
        assert(check == '100000000000000000000')
    })

    it('Creation of temporary blocks', async () => {
        const voom = await Voom.deployed()
        const tokenX = await TokenX.deployed()
        const accounts = await web3.eth.getAccounts()
        for (let i = 1; i <= 5; i++) {
            await tokenX.approve(voom.address, new BigNumber(1))
        }
        assert(true)
    })

    it('Transfer earnings to voom', async () => {
        const voom = await Voom.deployed()
        const tokenX = await TokenX.deployed()
        const accounts = await web3.eth.getAccounts()
        const balance = await tokenX.balanceOf.call(accounts[0])
        await tokenX.transfer(voom.address, balance)
        assert(true)
    })

    it('Change lasTime voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        const myDate = new Date()
        const date_start_user_1 = Math.floor(myDate.getTime() / 1000) - (2.3 * 86400)
        const date_start = Math.floor(myDate.getTime() / 1000) - (3 * 86400)
        await voom.setLastTime(accounts[1], date_start_user_1)
        if (accounts.length >= 30) {
            for (let i = 2; i <= 30; i++) {
                await voom.setLastTime(accounts[i], date_start)
            }
            assert(true)
        } else {
            assert(false)
        }
    })

    it('Claim voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        if (accounts.length >= 30) {
            for (let i = 1; i <= 30; i++) {
                await voom.claim({ from: accounts[i] })
            }
            assert(true)
        } else {
            assert(false)
        }
    })

    it('Validate claims', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        if (accounts.length >= 30) {
            const User_1 = await voom.vooms.call(accounts[1])
            const User_29 = await voom.vooms.call(accounts[29])
            const User_30 = await voom.vooms.call(accounts[30])
            assert(User_30.status == true && User_29.status == false && User_1.status == false)
        } else {
            assert(false)
        }
    })

    it('Deposit tokensX account 31 voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        const tokens = new BigNumber((100 * (10 ** 18)))
        await voom.deposit(tokens, accounts[30], { from: accounts[31] })
        const voom_new = await voom.vooms.call(accounts[30])       
        const total = new BigNumber(0).plus(voom_new.amountBonus).plus(voom_new.amountGain)
        assert(total.toString() == '0')
    })

    it('withdraw tokensX account 31 voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        await voom.withdraw({ from: accounts[31] })
        const User_31 = await voom.vooms.call(accounts[31])
        assert(User_31.withdraw.toString() == '1')
    })

    it('withdraw change time account 31 voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        const myDate = new Date()
        const date_start = Math.floor(myDate.getTime() / 1000) - (2 * 86400)        
        await voom.setDateWithdraw(accounts[31], date_start)
        assert(true)
    })

    it('withdraw after 24 hours tokensX account 31 voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        await voom.withdraw({ from: accounts[31] })
        const User_31 = await voom.vooms.call(accounts[31])
        assert(User_31.withdraw.toString() == '0')
        assert(User_31.status == false)
    })    
    
    it('Deposit tokensX account 32 voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        const tokens = new BigNumber((100 * (10 ** 18)))
        await voom.deposit(tokens, accounts[31], { from: accounts[32] })
        assert(true)
    })

    it('Change lasTime account 32', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        const myDate = new Date()
        const date_start = Math.floor(myDate.getTime() / 1000) - (3 * 86400)
        await voom.setLastTime(accounts[32], date_start)
        assert(true)
    })

    it('Reinvest account 32', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        const User_32_last = await voom.vooms.call(accounts[32])
        await voom.reinvest({ from: accounts[32] })
        const User_32_new = await voom.vooms.call(accounts[32])
        assert(User_32_last.amountDeposited < User_32_new.amountDeposited)
    })

    it('transferChef voom', async () => {
        const voom = await Voom.deployed()
        const tokenX = await TokenX.deployed()
        const accounts = await web3.eth.getAccounts()
        const balance_last = await tokenX.balanceOf.call(accounts[50])
        await voom.transferChef(accounts[32], accounts[50], "10000000000000000000")
        const balance_new = await tokenX.balanceOf.call(accounts[50])
        assert(balance_last.toString() == '0' && balance_new.toString() == '10000000000000000000')
    })

    it('setChef voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        await voom.setChef(accounts[1])
        const check = await voom.chef.call()
        assert(check == accounts[1])
    })

    it('setCommissions_1 voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        await voom.setCommissions_1(accounts[1])
        const check = await voom.commissions_1.call()
        assert(check == accounts[1])
    })
    
    it('setCommissions_2 voom', async () => {
        const voom = await Voom.deployed()
        const accounts = await web3.eth.getAccounts()
        await voom.setCommissions_2(accounts[1])
        const check = await voom.commissions_2.call()
        assert(check == accounts[1])
    })

    it('setNetworkPercentage voom', async () => {
        const voom = await Voom.deployed()
        const _value = "10000000000000000000"
        await voom.setNetworkPercentage(_value)
        const check = await voom.network_percentage.call()
        assert(check == _value)
    })

    it('setCommisionsPercentage voom', async () => {
        const voom = await Voom.deployed()
        const _value = "10000000000000000000"
        await voom.setCommisionsPercentage(_value)
        const check = await voom.commisions_percentage.call()
        assert(check == _value)
    })

    it('setTransferPercentage voom', async () => {
        const voom = await Voom.deployed()
        const _value = "10000000000000000000"
        await voom.setTransferPercentage(_value)
        const check = await voom.transfer_percentage.call()
        assert(check == _value)
    })

    it('setFastStartBonus voom', async () => {
        const voom = await Voom.deployed()
        const _value = "10000000000000000000"
        await voom.setFastStartBonus(_value)
        const check = await voom.fast_start_bonus.call()
        assert(check == _value)
    })

    it('setDubbing voom', async () => {
        const voom = await Voom.deployed()
        const _value = "10000000000000000000"
        await voom.setDubbing(_value)
        const check = await voom.dubbing.call()
        assert(check == _value)
    })

    it('setRefPercent voom', async () => {
        const voom = await Voom.deployed()
        const _value = "20"
        await voom.setRefPercent(0, _value)
        const check = await voom.refPercent.call(0)
        assert(check == _value)
    })

    it('setPaused voom', async () => {
        const voom = await Voom.deployed()
        const _value = true
        await voom.setPaused(_value)
        const check = await voom.paused.call()
        assert(check == _value)
    })

    it('has an Ownership', async () => {
        const voom = await Voom.deployed()
        assert(await voom.owner(), owner)
    })

    it('change Ownership', async () => {
        const accounts = await web3.eth.getAccounts()
        const voom = await Voom.deployed()
        const owner_last = await voom.owner()
        await voom.transferOwnership(accounts[1])
        const owner_new = await voom.owner()
        assert(owner_last != owner_new)
    })

    it('renounce Ownership', async () => {
        const accounts = await web3.eth.getAccounts()
        const voom = await Voom.deployed()
        const owner_last = await voom.owner()
        await voom.renounceOwnership({ from: accounts[1] })
        const owner_new = await voom.owner()
        assert(owner_last != owner_new)
    })

})