from brownie import *
from helpers.constants import MaxUint256


def test_are_you_trying(deployer, vault, strategy, want, governance):
    """
    Verifies that you set up the Strategy properly
    """
    # Setup
    startingBalance = want.balanceOf(deployer)
    print(f'Starting Amount : {startingBalance}')

    depositAmount = startingBalance // 2
    assert startingBalance >= depositAmount
    assert startingBalance >= 0
    # End Setup

    # Deposit
    assert want.balanceOf(vault) == 0

    want.approve(vault, MaxUint256, {"from": deployer})
    print(f'Deposit Amount : {depositAmount}')
    vault.deposit(depositAmount, {"from": deployer})

    available = vault.available()
    assert available > 0
    print('Available amount ')

    vault.earn({"from": governance})

    chain.sleep(10000 * 13)  # Mine so we get some interest

    ## TEST 1: Does the want get used in any way?
    assert want.balanceOf(vault) == depositAmount - available

    # Did the strategy do something with the asset?
    assert want.balanceOf(strategy) < available

    # Use this if it should invest all
    # assert want.balanceOf(strategy) == 0

    # Change to this if the strat is supposed to hodl and do nothing
    # assert strategy.balanceOf(want) = depositAmount

    ## TEST 2: Is the Harvest profitable?
    harvest = strategy.harvest({"from": governance})
    event = harvest.events["Harvested"]
    # If it doesn't print, we don't want it
    # assert event["amount"] > 0
    print(f'Harvested amount : {event["amount"]}')

    ## TEST 3: Does the strategy emit anything?
    event = harvest.events["TreeDistribution"]
    assert event["token"] == "0xf1Dc500FdE233A4055e25e5BbF516372BC4F6871" ## Add token you emit
    assert event["amount"] > 0 ## We want it to emit something