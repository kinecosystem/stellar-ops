#!/usr/bin/env python
"""Calculate KIN in circulation and return a dictionary with the results.

Kin in circulation is calculated by taking the total KIN amount (10 trillion)
and subtracting KIN left in the root account, unvested KIN from Kin Foundation
account, and the swap account.
"""

import asyncio
import json
import os
import sys
from decimal import Decimal

sys.path.append(os.path.abspath(os.path.join(__file__, '..', 'vendor')))
from aiohttp import ClientSession, ClientTimeout


TOTAL_KIN_AMOUNT = 10e12  # 10 Trillion

# Account addresses
ACCOUNTS = {
    'root': 'GB6FYT67FZHUOE4ZXEUJCLHLIWIIRYK5DTF57YKNEH33GQWMTQCVWLZ3',
    'unvested': 'GAJX4OVQRDJDNLIBWI3IBNEJU6QNGT3DZOOFMUV2Y7HTTZUDRGM6GU75',
    'swap': 'GD7WVPLRHJRGGX6ZHYQT5RQCPAEEVH73SV4UW7MBEUGVKFZC47U5VPBI',
}

HORIZON_ADDR = 'https://horizon.kinfederation.com'
HORIZON_REQUEST_TIMEOUT = 10


async def get_balances(client):
    """Get balances for special accounts important to calculate total KIN in circulation."""
    balances = {}

    async def get_balance(client, account_name, account_address):
        async with client.get(f'{HORIZON_ADDR}/accounts/{account_address}') as res:
            data = await res.json()

        # get first item
        balances[account_name] = next(
            token['balance']
            for token in data['balances']
            if token['asset_type'] == 'native')

    futures = []
    for account_name, account_address in ACCOUNTS.items():
        futures.append(asyncio.create_task(get_balance(client, account_name, account_address)))
        await asyncio.sleep(0)

    await asyncio.gather(*futures)

    return balances


def calculate_kin_in_cicrulation(total_kin_amount, balances):
    """Calculate KIN in circulation depending on given balances of important accounts."""
    # decimal are used for float precision expected by humans.
    # https://docs.python.org/3.7/library/decimal.html
    return Decimal(total_kin_amount) - sum(Decimal(b) for b in balances.values())


async def main():
    async with ClientSession(
            raise_for_status=True,
            timeout=ClientTimeout(total=HORIZON_REQUEST_TIMEOUT),
    ) as client:

        balances = await get_balances(client)

    tokens_in_circulation = calculate_kin_in_cicrulation(TOTAL_KIN_AMOUNT, balances)

    return float(tokens_in_circulation)

    # debug
    # print(
    #     json.dumps({
    #         'status_code': 200,
    #         'body': {
    #             **{'tokens_in_circulation': str(tokens_in_circulation)},
    #             **balances,
    #             }
    #     }
    # ))

# debug
# if __name__ == '__main__':
#     asyncio.run(main())


def lambda_handler(_, __):
    return asyncio.run(main())
