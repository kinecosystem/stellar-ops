# from deploy.utils.coreTemplate import build_cfg
import os


def build_cfg(db_name, db_user, db_password, network_passphrase, preferred_peers, node_seed, node_name, is_validator,
              nodes_names, validators):
    '''
    :param db_name: str
    :param db_user: str
    :param db_password: str
    :param network_passphrase: str
    :param preferred_peers: str - list of hostnames, ex: "test1.test.org", "test2.test.org", "test.again.google.com"
    :param node_seed: str the unique seed of the node
    :param node_name: str thisis-node
    :param is_validator: str true or false
    :param nodes_names: str - list of nodes names and public address: "GCU4.. test1", "CVI4.. test2", "CV5.. test.again"
    :param validators: str - list of nodes names with prefix $: "$test1","$test2","$test.again"
    :return: str that represent fully configured for core.
    '''
    return f'''AUTOMATIC_MAINTENANCE_PERIOD=1800
TARGET_PEER_CONNECTIONS = 50
HTTP_PORT = 11626
PUBLIC_HTTP_PORT = true

WHITELIST = "GCPGMBNS42RQODVI7JCIRZDOO2PKS3BDNHEL45YMB7PLGJP65FS7U4UV"

LOG_FILE_PATH = ""

COMMANDS = ["ll?level=warn"]

DATABASE = "postgresql://dbname={db_name} host=/var/run/postgresql user={db_user} password={db_password}"

NETWORK_PASSPHRASE = "{network_passphrase}"

# REMOVE SELF FROM PREFERRED
PREFERRED_PEERS = [ {preferred_peers} ]

CATCHUP_RECENT = 0

# INSERT SELF SEED AND NAME WITHOUT DOMAIN
NODE_SEED="{node_seed} {node_name}"

NODE_IS_VALIDATOR = {is_validator}

# REMOVE SELF FROM NODE_NAMES
NODE_NAMES = [ {nodes_names} ]

[QUORUM_SET]
THRESHOLD_PERCENT = 67
VALIDATORS = [ {validators} ]
''' + '''
[HISTORY.local]
get = "cp /data/core-history/history/vs/{0} {1}"
put = "cp {0} /data/core-history/history/vs/{1}"
mkdir = "mkdir -p /data/core-history/history/vs/{0}"

# vi: ft=toml'
'''


CFG_FILE_LOCATION = "/data/stellar-core/stellar-core.cfg"
if __name__ == '__main__':
    VALIDATOR = True
    all_nodes = {'node1': 'GKYGDERGG', 'node2': 'SGHSRTHHR', 'node3': 'SDGHBSDGB', 'node4': 'SGDHSGDGH'}
    db_name = "my_db_name"
    db_user = "this-is-user"
    db_password = 'nice-password'
    network_pass = "YOGEV NETWORK 2019"
    domain = '.my.domain.com'

    self_node_name = 'node3'
    self_node_seed = 'sssdddd'

    nodes_name = list(all_nodes.keys())
    nodes_pairs = '\n'
    validators = '\n'
    preferred_pairs = '\n'
    validator_state = 'true' if VALIDATOR else 'false'
    for k, v in all_nodes.items():
        if k != self_node_name:
            nodes_pairs += f'\"{v} {k}\",\n'
            preferred_pairs += f'\"{k + domain}\",\n'
        validators += f'\"${k}\",\n'
    cfg_data = build_cfg(db_name, db_user, db_password, network_pass, preferred_pairs, self_node_seed, self_node_name,
                         validator_state, nodes_pairs, validators)
    with open(CFG_FILE_LOCATION,'w') as f:
        f.write(cfg_data)