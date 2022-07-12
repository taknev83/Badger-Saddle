import brownie
from brownie import *
from helpers.constants import MaxUint256
from helpers.SnapshotManager import SnapshotManager
from helpers.time import days

"""
  TODO: Put your tests here to prove the strat is good!
  See test_harvest_flow, for the basic tests
  See test_strategy_permissions, for tests at the permissions level
"""


def test_my_custom_test(deployed):
    assert True

def test_withdrawAll(deployer, vault, strategy, want, governance, LPToken, StkLPToken):
    startingBalance = want.balanceOf(deployer)

    depositAmount = startingBalance // 2
    assert startingBalance >= depositAmount
    assert startingBalance >= 0
    print(f'Starting Balance : {startingBalance}')
    print(f'Deposit Amount : {depositAmount}')
    # End Setup
 
    # Deposit
    assert want.balanceOf(vault) == 0

    want.approve(vault, MaxUint256, {"from": deployer})
    vault.deposit(depositAmount, {"from": deployer})

    available = vault.available()
    assert available > 0
    print(f"Valut want : {want.balanceOf(vault)}")
    vault.earn({"from": governance})
    print(f"Valut want after earn : {want.balanceOf(vault)}")
    print(f"Strategy LP Token after deposit : {LPToken.balanceOf(strategy)}")
    print(f"Strategy STKLP Token after deposit : {StkLPToken.balanceOf(strategy)}")



    week = 60 * 60 * 24 * 7
    chain.sleep(week)
    chain.mine(10)

    harvest = strategy.harvest({"from": governance})

    withdraw = strategy.withdraw(9500, {"from": vault})
    print(f"Valut want after withdraw : {want.balanceOf(vault)}")
    print(f"Strategy LP Token after withdraw : {LPToken.balanceOf(strategy)}")
    print(f"Strategy STKLP Token after withdraw : {StkLPToken.balanceOf(strategy)}")




	


