// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol';
import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import "./libraries/Members.sol";

contract Voom is Members  {

    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256[7] public refPercent = [20, 5, 10, 12, 15, 18, 20];
    uint256 public fast_start_bonus = 20;
    uint256 public daily = 0.7 ether;
    bool public paused;

    struct VoomStruct {
        bool isExist;
        uint id;
        address voom;
        uint256 amountUser;
        uint256 amountPromise;
        uint256 amountGain;
        uint256 amountGainNetwork;
        uint256 amountBonus;
        uint256 lastTime;
        uint created;
        uint256 dateWithdraw;
        uint256 withdraw;
        uint256 amountWithdraw;
        bool status;
    }
    mapping(address => VoomStruct) public vooms;
    mapping(uint256 => address) public voomsList;
    uint256 public lastVoom;
    uint256 public withdrawGlobal;

    IBEP20 public usdt = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    address chef;
    address commissions_1;
    address commissions_2;
    
    constructor(address _chef, address _commissions_1, address _commissions_2) public {
        chef = _chef;
        commissions_1 = _commissions_1;
        commissions_2 = _commissions_2;
    }

    function setChef(address _value) onlyOwner external {
        chef = _value;
    }

    function setCommissions_1(address _value) onlyOwner external {
        commissions_1 = _value;
    }

    function setCommissions_2(address _value) onlyOwner external {
        commissions_2 = _value;
    }

    function setDaily(uint256 _value) onlyOwner external {
        daily = _value;
    }

    function setFastStartBonus(uint256 _value) onlyOwner external {
        fast_start_bonus = _value;
    }

    function setRefPercent(uint256 _position , uint256 _value) onlyOwner external {
        refPercent[_position] = _value;
    }

    function setPaused(bool _value) onlyOwner external {
        paused = _value;
    }

    function deposit(uint256 _amount, address _ref) external {
        registerUser(_ref);
        require(paused == false, "!paused");
        usdt.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 _amountSponsor = _amount.mul(fast_start_bonus).div(100);
        _amount = _amount.sub(_amountSponsor);
        if(_amountSponsor > 0){
            address[] memory refTree = getParentTree(msg.sender, 1);
            if(vooms[refTree[0]].status == true){
                uint256 _amountCheckSponsor = vooms[refTree[0]].amountGain.add(vooms[refTree[0]].amountGainNetwork).add(vooms[refTree[0]].amountBonus);
                if(_amountCheckSponsor < vooms[refTree[0]].amountPromise){
                    uint256 _amountValue = vooms[refTree[0]].amountPromise.sub(_amountCheckSponsor);
                    if(_amountValue >= _amountSponsor){
                        _amountValue = _amountSponsor;
                    }
                    emit eventBonus(refTree[0], msg.sender, _amountValue, now);
                    usdt.safeTransfer(address(refTree[0]), _amountValue);
                    vooms[refTree[0]].amountBonus = vooms[refTree[0]].amountBonus.add(_amountValue);
                    _amountCheckSponsor = vooms[refTree[0]].amountGain.add(vooms[refTree[0]].amountGainNetwork).add(vooms[refTree[0]].amountBonus);
                    if(_amountCheckSponsor >= vooms[refTree[0]].amountPromise){
                        vooms[refTree[0]].status = false;
                    }
                }
            }
        }
        if(vooms[msg.sender].isExist){
            vooms[msg.sender].amountUser = vooms[msg.sender].amountUser.add(_amount);
            vooms[msg.sender].amountPromise = vooms[msg.sender].amountPromise.add(_amount.mul(2));
            vooms[msg.sender].status = true;
            vooms[msg.sender].lastTime = now;
            vooms[msg.sender].withdraw = 0;
            vooms[msg.sender].dateWithdraw = 0;          
            vooms[msg.sender].amountWithdraw = 0;
            emit eventDeposit(msg.sender, _amount, now);
        } else {
            VoomStruct memory voom_struct;
            voom_struct = VoomStruct({
                isExist: true,
                id: lastVoom,
                voom: msg.sender,
                amountUser: _amount,
                amountPromise: _amount.mul(2),
                amountGain: 0,
                amountGainNetwork: 0,
                amountBonus: 0,
                lastTime: now,
                dateWithdraw: 0,
                withdraw: 0,
                amountWithdraw: 0,
                created: now,
                status: true
            });
            vooms[msg.sender] = voom_struct;
            lastVoom++;
            voomsList[lastVoom] = msg.sender;
            emit eventDeposit(msg.sender, _amount, now);
        }
        _amount = _amount.mul(90).div(100);
        if(_amount > 0){
            usdt.safeTransfer(chef, _amount);
        }
    }

    function claim() external {
        require(vooms[msg.sender].status == true, "!claimFinish");
        require(vooms[msg.sender].withdraw == 0, "!claimWithdraw");
        require(balanceUSDT() >= pending(msg.sender), "!claimBalance");
        require(pending(msg.sender) > 0, "!claimPending");
        uint256 _pending = pending(msg.sender);
        uint256 _amountCheck = vooms[msg.sender].amountGain.add(vooms[msg.sender].amountGainNetwork).add(vooms[msg.sender].amountBonus);
        if(_amountCheck < vooms[msg.sender].amountPromise){
            uint256 _amountValue = vooms[msg.sender].amountPromise.sub(_amountCheck);
            if(_amountValue >= _pending){
                _amountValue = _pending;
            }
            emit eventGain(msg.sender, _amountValue, now);
            usdt.safeTransfer(msg.sender, _amountValue);
            vooms[msg.sender].amountGain = vooms[msg.sender].amountGain.add(_amountValue);
            _amountCheck = vooms[msg.sender].amountGain.add(vooms[msg.sender].amountGainNetwork).add(vooms[msg.sender].amountBonus);
            if(_amountCheck >= vooms[msg.sender].amountPromise){
                vooms[msg.sender].status = false;
            }
            vooms[msg.sender].lastTime = now;
            uint256 _pendingNetwork = _amountValue.div(2);
            uint256 _pendingCommisions = _amountValue;
            address[] memory refTree = getParentTree(msg.sender, 7);
            for (uint256 i = 0; i < 7; i++) {
                uint256 refAmount = _pendingNetwork.mul(refPercent[i]).div(100);
                if (refTree[i] != address(0) && _pendingNetwork > 0 && refAmount > 0) {
                    address _ref = refTree[i];
                    uint256 _amountCheckSponsor = vooms[_ref].amountGain.add(vooms[_ref].amountGainNetwork).add(vooms[_ref].amountBonus);
                    if(vooms[_ref].status == true){
                        if(_amountCheckSponsor < vooms[_ref].amountPromise){
                            uint256 _amountValueSponsor = vooms[_ref].amountPromise.sub(_amountCheckSponsor);
                            if(_amountValueSponsor >= refAmount){
                                _amountValueSponsor = refAmount;
                            }
                            if(balanceUSDT() >= _amountValueSponsor){
                                emit eventNetwork(_ref, msg.sender, _amountValueSponsor, now);
                                usdt.safeTransfer(_ref, _amountValueSponsor);
                                vooms[_ref].amountGainNetwork = vooms[_ref].amountGainNetwork.add(_amountValueSponsor);
                                _amountCheckSponsor = vooms[_ref].amountGain.add(vooms[_ref].amountGainNetwork).add(vooms[_ref].amountBonus);
                                if(_amountCheckSponsor >= vooms[_ref].amountPromise){
                                    vooms[_ref].status = false;
                                }
                            }
                        }
                    }
                } else {
                    break;
                }
            }
            if(balanceUSDT() >= _pendingCommisions){
                usdt.safeTransfer(commissions_1, _pendingCommisions.div(2));
                usdt.safeTransfer(commissions_2, _pendingCommisions.div(2));
            }
        } else {
            vooms[msg.sender].status = false;
        }
    }

    function withdraw() external {
        require(paused == false, "!paused");
        require(vooms[msg.sender].status == true, "!withdrawStatusFinish");
        uint256 _amountCheck = vooms[msg.sender].amountGain.add(vooms[msg.sender].amountGainNetwork).add(vooms[msg.sender].amountBonus);
        require(_amountCheck < vooms[msg.sender].amountUser, "!withdrawGainFinish");
        if(vooms[msg.sender].withdraw == 0){
            vooms[msg.sender].withdraw = 1;
            vooms[msg.sender].dateWithdraw = now;          
            vooms[msg.sender].amountWithdraw = vooms[msg.sender].amountUser.sub(_amountCheck);
            withdrawGlobal = withdrawGlobal.add(vooms[msg.sender].amountWithdraw);
        } else if(vooms[msg.sender].withdraw == 1){
            uint256 timeBetweenLastWithdraw = now - vooms[msg.sender].dateWithdraw;
            if(timeBetweenLastWithdraw >= 1 days){
                if(balanceUSDT() >= vooms[msg.sender].amountWithdraw){
                    emit eventWithdraw(msg.sender, vooms[msg.sender].amountWithdraw, now);
                    usdt.safeTransfer(msg.sender, vooms[msg.sender].amountWithdraw);
                    vooms[msg.sender].withdraw = 2;
                    vooms[msg.sender].status = false;
                    withdrawGlobal = withdrawGlobal.sub(vooms[msg.sender].amountWithdraw);
                } else {
                    revert("!withdrawBalanceFinish");
                }
            } else {
                revert("!withdrawTimeFinish");
            }
        } else {
            revert("!withdrawFinish");
        }
    }

    function pending(address _user) public view returns (uint256) {
        uint256 timeBetweenLastTime = now - vooms[_user].lastTime;
        uint256 usdtInPool = vooms[_user].amountUser;
        uint256 dayInSeconds = 1 days;
        return (usdtInPool.mul(daily).mul(timeBetweenLastTime)).div(dayInSeconds).div(100 ether);
    }

    function balanceUSDT() public view returns(uint256){
        return usdt.balanceOf(address(this));
    }

    event eventBonus(address indexed _user, address indexed _referred, uint256 _amount, uint256 _time);
    event eventDeposit(address indexed _user, uint256 _amount, uint256 _time);
    event eventGain(address indexed _user, uint256 _amount, uint256 _time);
    event eventNetwork(address indexed _user, address indexed _referred, uint256 _amount, uint256 _time);
    event eventWithdraw(address indexed _user, uint256 _amount, uint256 _time);
    
}