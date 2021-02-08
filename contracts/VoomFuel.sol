// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol';
import "./VoomFuelUser.sol";
import "./interfaces/IPool.sol";

contract VoomFuel is Ownable  {

    using SafeMath for uint256;

    mapping(address => bool) public mod;

    VoomFuelUser[] public vooms;
    uint public countVooms;

    IMembers public member;
    address public dev;
    address chef;

    uint256 public amountUser;
    uint256 public amountBonus;
    uint256 public amountPromise;
    uint256 public amountGain;
    uint256 public amountGainNetwork;
    uint256 public tokensLP;
    bool public finish;

    struct VoomStruct {
        bool isExist;
        uint id;
        address voom;
        address owner;
        uint256 amountUser;
        uint256 amountPromise;
        uint256 amountGain;
        uint256 amountGainNetwork;
        uint256 tokensLP;
        uint256 amountBonus;
        uint created;
        bool status;
    }
    mapping(address => uint256) public userCountVooms;
    mapping(address => mapping(uint256 => VoomStruct)) public userListVooms;
    mapping(address => VoomStruct) public userVooms;
    
    constructor(IMembers _member, address _dev, address _chef) public {
        member = _member;
        dev = _dev;
        chef = _chef;
    }

    modifier onlyMod() {
        require(mod[msg.sender] || msg.sender == owner(), "Must be mod");
        _;
    }

    function setFinish(bool _status) onlyOwner external {
        finish = _status;
    }

    function createVoom(address ref) external {
        if(member.isMember(ref) == false){
            ref = member.membersList(0);
        }
        if(member.isMember(msg.sender) == false){
            member.addMember(msg.sender, ref);
        }

        VoomFuelUser _voom = new VoomFuelUser(msg.sender, member, dev, chef, address(this), userCountVooms[msg.sender]);
        vooms.push(_voom);

        VoomStruct memory voom_struct;

        voom_struct = VoomStruct({
            isExist: true,
            id: userCountVooms[msg.sender],
            voom: address(_voom),
            owner: msg.sender,
            amountUser: 0,
            amountPromise: 0,
            amountGain: 0,
            amountGainNetwork: 0,
            tokensLP: 0,
            amountBonus: 0,
            created: now,
            status: true
        });
        userListVooms[msg.sender][userCountVooms[msg.sender]] = voom_struct;
        userCountVooms[msg.sender]++;
        countVooms++;

        if(userVooms[msg.sender].isExist == false){
            userVooms[msg.sender] = voom_struct;
        }

        mod[address(_voom)] = true;

    }

    function deposit(uint256 _amountUser, uint256 _amountPromise, uint256 _amountBonus, uint256 _tokensLP, uint256 _pid, address _user) onlyMod external {
        require(finish == false, "!finish");
        amountUser = amountUser.add(_amountUser);
        amountPromise = amountPromise.add(_amountPromise);
        amountBonus = amountBonus.add(_amountBonus);
        tokensLP = tokensLP.add(_tokensLP);

        userListVooms[_user][_pid].amountUser = userListVooms[_user][_pid].amountUser.add(_amountUser);
        userListVooms[_user][_pid].amountPromise = userListVooms[_user][_pid].amountPromise.add(_amountPromise);      
        userListVooms[_user][_pid].amountBonus = userListVooms[_user][_pid].amountBonus.add(_amountBonus);
        userListVooms[_user][_pid].tokensLP = userListVooms[_user][_pid].tokensLP.add(_tokensLP);

        userVooms[_user].amountUser = userVooms[_user].amountUser.add(_amountUser);
        userVooms[_user].amountPromise = userVooms[_user].amountPromise.add(_amountPromise);
        userVooms[_user].amountBonus = userVooms[_user].amountBonus.add(_amountBonus);
        userVooms[_user].tokensLP = userVooms[_user].tokensLP.add(_tokensLP);
    }

    function claim(uint256 _amountGain, uint256 _amountGainNetwork, bool _check, uint256 _pid, address _user) onlyMod external {
        require(finish == false, "!finish");
        amountGain = amountGain.add(_amountGain);
        amountGainNetwork = amountGainNetwork.add(_amountGainNetwork);
        userListVooms[_user][_pid].amountGain = userListVooms[_user][_pid].amountGain.add(_amountGain);
        userListVooms[_user][_pid].amountGainNetwork = userListVooms[_user][_pid].amountGainNetwork.add(_amountGainNetwork);
        userVooms[_user].amountGain = userVooms[_user].amountGain.add(_amountGain);
        userVooms[_user].amountGainNetwork = userVooms[_user].amountGainNetwork.add(_amountGainNetwork);
        if(_check == true){
            userListVooms[_user][_pid].status = false; 
        }
    }

    function withdraw(uint256 _pid, address _user) onlyMod external {
        userListVooms[_user][_pid].status = false; 
    }

    function pending(address _user) external view returns(uint256) {
        if(userCountVooms[_user] == 0){
            return 0;
        }
        if(finish == true){
            return 0;
        }
        uint256 _amount = 0;
        for (uint256 i = 0; i < userCountVooms[_user]; i++) {
            _amount = _amount.add(IPool(address(userListVooms[_user][i].voom)).pending());
        }
        return _amount;
    }

}

