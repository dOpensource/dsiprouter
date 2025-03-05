import ldap
from typing import Dict, List, Tuple


def filterValidSearchResults(
    raw_result: List[Tuple[str, Dict[str, List[bytes]]]]
) -> List[Tuple[str, Dict[str, List[bytes]]]]:
    return [
        res for res in raw_result if res[0] is not None
    ]

def filterSearchValuesByRdn(raw_values: List[bytes], rdn: str) -> List[str]:
    rdn_filter = f'{rdn}='
    return [
        next(
            (dn for dn in ldap.dn.explode_dn(val) if rdn_filter in dn),
            ''
        ).replace(rdn_filter, '') for val in raw_values
    ]
