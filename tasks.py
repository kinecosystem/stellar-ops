"""Call various Terraform actions."""
import os
import os.path
from datetime import datetime, timezone
from hashlib import sha256
from time import sleep

import requests
from invoke import task, call
from invoke.exceptions import Exit

from kin_base import Keypair as BaseKeypair, Builder as BaseBuilder
from kin import KinClient, Environment as KinEnvironment
from kin.blockchain.builder import Builder


PASSPHRASE = 'private testnet'
WHITELIST_SEED = 'SDT3NSHBLRUKT5V6KXP7HTPCHPB6LPUVTWVHSKQJKHXUA3IOUJMCTLBQ'
WHITELIST_ADDRESS = BaseKeypair.from_seed(WHITELIST_SEED).address().decode()

HORIZON_ENDPOINT = 'http://localhost:8000'
CORE_ENDPOINT = 'http://localhost:11626'


@task
def vendor(c, production=True):
    """Vendor go dependencies."""
    print('Vendoring dependencies')
    if not os.path.isdir('{}/vendor'.format(c.cwd)):
        if production:
            c.run('sudo docker run '
                  '--rm '
                  '-v {}/{}:/go/src/github.com/kinecosystem/go '
                  'kinecosystem/horizon-build '
                  'dep ensure'.format(os.getcwd(), c.cwd))
        else:
            c.run('sudo docker-compose run horizon-build dep ensure')


def is_image_exists(c, name):
    """Return true if given Docker image exists."""
    res = c.run('sudo docker images', hide='stdout')
    for image in res.stdout.split('\n'):
        if name == image.split(' ')[0]:
            print('Image {name} exists'.format(name=name))
            return True

    print('Image {name} doesn\'t exist'.format(name=name))
    return False


def is_git_dir_modified(c):
    """Return True if the given git repo directory is unmodified."""
    res = c.run('git status --porcelain', hide='both')
    for line in res.stdout:
        if line.startswith(' M '):
            print('Git directory {} is modified'.format(c.cwd))
            return True

    print('Git directory {} is unmodified'.format(c.cwd))
    return False


def git_dir_checkout_branch(c, org_name, repo_name, remote, branch):
    """Checkout a specific branch for given repo directory."""
    print('Fetching updates from Git repository')
    c.run('git remote add {remote} git@github.com:{org_name}/{repo_name}.git'.format(remote=remote, org_name=org_name, repo_name=repo_name),
          warn=True)
    c.run('git fetch {} {}'.format(remote, branch))

    print('Checking out {}/{}'.format(remote, branch))
    c.run('git checkout {}/{}'.format(remote, branch))

    print('Pulling {}/{}'.format(remote, branch))
    c.run('git pull {} {}'.format(remote, branch))


def init_git_repo(c, repo_name, org_name='kinecosystem', remote='origin', branch='master'):
    """Make sure git repo directory is available before building."""
    # clone git repo if it doesn't exist,
    # otherwise checkout master branch
    dir_name = '{}-git'.format(repo_name)
    git_url = 'https://github.com/{}/{}.git'.format(org_name, repo_name)

    if not os.path.isdir('{}/{}/volumes/{}'.format(os.getcwd(), c.cwd, dir_name)):
        print('%s git repository doesn\'t exist, cloning' % repo_name)
        c.run('git clone --branch {branch} {git_url} volumes/{dir_name}'.format(branch=branch, git_url=git_url, dir_name=dir_name))
    else:
        with c.cd('volumes/{}'.format(dir_name)):
            if is_git_dir_modified(c):
                raise Exit('Stopping, please clean changes and retry')

            git_dir_checkout_branch(c, org_name, repo_name, remote, branch)

    return dir_name


@task
def build_core(c, version, org_name='kinecosystem', repo_name='core', remote='origin', branch='master', production=True):
    """Build Core binary docker image.

    By default, builds a Docker image tagged ready for production.

    When production is disabled, it builds using docker-compose without properly tagging,
    mainly used for local network tests.
    """
    with c.cd('images'):
        # we always rebuild production images,
        # but we don't for non-production (e.g. local test network)
        #
        # NOTE docker compose doesn't have a way of knowing if an image was already
        # built, so we search for it manually
        if not production and is_image_exists(c, 'images_{}'.format(repo_name)):
            return

        dir_name = init_git_repo(c, repo_name, org_name, remote, branch)

        print('Building core')

        if production:
            c.run('sudo docker build '
                  '-f dockerfiles/Dockerfile.stellar-core-build '
                  '-t {org_name}/stellar-core-build '
                  '.'.format(org_name=org_name))

            c.run('sudo docker run --rm '
                  '-v {cwd}/{pwd}/volumes/{dir_name}:/stellar-core '
                  '{org_name}/stellar-core-build'.format(
                      cwd=os.getcwd(),
                      pwd=c.cwd,
                      org_name=org_name,
                      repo_name=repo_name,
                      dir_name=dir_name,
                      ))

            c.run('sudo docker build '
                  '-f dockerfiles/Dockerfile.stellar-core '
                  '-t {org_name}/{repo_name}:latest '
                  '-t {org_name}/{repo_name}:{version} '
                  '.'.format(org_name=org_name, repo_name=repo_name, version=version))
        else:
            c.run('sudo docker-compose build stellar-core-build')
            c.run('sudo docker-compose run stellar-core-build')
            c.run('sudo docker-compose build stellar-core')


@task
def build_go(c, version, org_name='kinecosystem', repo_name='go', remote='origin', branch='master', app='horizon', production=True):
    """Build Horizon binary docker images and other misc. Golang apps.

    By default, builds a Docker image tagged ready for production.

    When production is disabled, it builds using docker-compose without properly tagging,
    mainly used for local network tests.
    """
    with c.cd('images'):
        # we always rebuild production images,
        # but we don't for non-production (e.g. local test network)
        #
        # NOTE docker compose doesn't have a way of knowing if an image was already
        # built, so we search for it manually
        if not production and is_image_exists(c, 'images_{}'.format(app)):
            return

        dir_name = init_git_repo(c, repo_name, org_name, remote, branch)

        cmd = ' '.join([
            'bash', '-c',
            ('"go build -ldflags=\''
             '-X \\"github.com/{org_name}/{repo_name}/support/app.buildTime={timestamp}\\"'
             ' '
             '-X \\"github.com/{org_name}/{repo_name}/support/app.version={version}\\"'
             ' \''
             ).format(
                 org_name=org_name,
                 repo_name=repo_name,
                 timestamp=datetime.now(timezone.utc).isoformat(),
                 version=version),
            '-o', './{}'.format(app), './services/{}"'.format(app),
        ])

        print('Building {}'.format(app.capitalize()))

        # build go app compile environment
        #
        # NOTE horizon-build docker image is used to build any Golang app
        # since they share the same dependencies
        if production:
            c.run('sudo docker build '
                  '-f dockerfiles/Dockerfile.horizon-build '
                  '-t {org_name}/horizon-build '
                  '.'.format(org_name=org_name))
        else:
            # build using docker compose for local test network
            c.run('sudo docker-compose build horizon-build')

        with c.cd('volumes/{}'.format(dir_name)):
            vendor(c, production)

        if production:
            # compile go app
            c.run('sudo docker run '
                  '--rm '
                  '-v {cwd}/{pwd}/volumes/{dir_name}:/{repo_name}/src/github.com/{org_name}/{repo_name} '
                  '{org_name}/horizon-build '
                  '{cmd}'.format(
                      cwd=os.getcwd(),
                      pwd=c.cwd,
                      org_name=org_name,
                      repo_name=repo_name,
                      dir_name=dir_name,
                      cmd=cmd))

            # build runtime image (copy binary into image)
            c.run('sudo docker build '
                  '-f dockerfiles/Dockerfile.{app} '
                  '-t {org_name}/{app}:latest '
                  '-t {org_name}/{app}:{version} '
                  '.'.format(org_name=org_name, app=app, version=version))
        else:
            # build using docker compose for local test network

            # compile go app
            c.run('sudo docker-compose run horizon-build {cmd}'.format(cmd=cmd))

            # build runtime image (copy binary into image)
            c.run('sudo docker-compose build {}'.format(app))


@task
def push_dockerhub(c, app, version, latest=True):
    """Push image to Dockerhub."""
    if app.lower() == 'core':
        c.run('sudo docker push kinecosystem/stellar-core:{version}'.format(version=version))
        if latest:
            c.run('sudo docker push kinecosystem/stellar-core:latest')
    elif app.lower() == 'horizon':
        c.run('sudo docker push kinecosystem/horizon:{version}'.format(version=version))
        if latest:
            c.run('sudo docker push kinecosystem/horizon:latest')
    elif app.lower() == 'friendbot':
        c.run('sudo docker push kinecosystem/friendbot:{version}'.format(version=version))
        if latest:
            c.run('sudo docker push kinecosystem/friendbot:latest')
    else:
        Exit('Unknown application {}'.format(app))


@task
def rm_network(c):
    """Destroy local test network."""
    print('Stopping local test network and removing containers')
    with c.cd('images'):
        c.run('sudo docker-compose down -v', hide='stderr')

        c.run('sudo rm -rf volumes/stellar-core/opt/stellar-core/buckets')
        c.run('sudo rm -f volumes/stellar-core/opt/stellar-core/*.log')
        c.run('sudo rm -rf volumes/stellar-core/tmp')


def upgrade(param, ledger_param, value):
    """Apply Core network parameter upgrade."""
    while True:
        r = requests.get('{}/upgrades'.format(CORE_ENDPOINT),
                         params={'mode': 'set', 'upgradetime': '1970-01-01T00:00:00Z', param: value})
        r.raise_for_status()

        r = requests.get('{}/ledgers?order=desc&limit=1'.format(HORIZON_ENDPOINT),
                         params={'order': 'desc', 'limit': 1})
        r.raise_for_status()
        res = r.json()
        records = res['_embedded']['records']
        # NOTE records can be empty if called straight after network has started
        # since no ledgers have been added yet
        if records and int(records[0][ledger_param]) == value:
            break

        sleep(1)


def base_reserve_0():
    """Set base reserve to 0, necessary for spam prevention tests."""
    print('Setting base reserve to 0')
    upgrade('basereserve', 'base_reserve_in_stroops', 0)


def protocol_version_9():
    """Protocol is already at 9, but this fixes a bug which prevents manageData ops."""
    print('Setting protocol version to 9')
    upgrade('protocolversion', 'protocol_version', 9)


def tx_set_size_500():
    """Set transactino set size to 500."""
    print('Setting transaction set size to 500')
    upgrade('maxtxsize', 'max_tx_set_size', 500)


def derive_root_account_seed(passphrase):
    """Return the root account seed based on the given network passphrase."""
    network_hash = sha256(passphrase.encode()).digest()
    return BaseKeypair.from_raw_seed(network_hash).seed().decode()


@task
def root_account_seed(_, passphrase):
    """Print root account seed according to given network passphrase."""
    print(derive_root_account_seed(passphrase))


@task
def address_from_seed(_, seed):
    """Print account address according to given seed."""
    print(BaseKeypair.from_seed(seed).address().decode())


@task
def generate_whitelist_address_xdr(_, passphrase, whitelist_address, account_sequence, address_to_whitelist):
    """Generate Append Data operation XDR, used to whitelist an address."""
    # initialize tx builder
    #
    # NOTE fee is 0 because it's a transaction on the whitelist account which
    # is always prioritized
    builder = BaseBuilder(network=passphrase, address=whitelist_address, sequence=int(account_sequence), fee=0)

    # build "Append Data" transaction with (address, hint) key:value pair.
    kp = BaseKeypair.from_address(address_to_whitelist)
    builder.append_manage_data_op(kp.address().decode(), kp.signature_hint())

    # generate xdr
    xdr = builder.gen_xdr()

    print(xdr.decode())


def create_whitelist_account():
    """Create whitelist account for prioritizing transactions in tests."""
    print('Creating whitelist account')

    env = KinEnvironment('LOCAL', HORIZON_ENDPOINT, PASSPHRASE)
    root_client = KinClient(env)
    root_seed = derive_root_account_seed(PASSPHRASE)
    builder = Builder(env.name, root_client.horizon, 100, root_seed)

    builder.append_create_account_op(WHITELIST_ADDRESS, str(100e5))
    builder.sign()
    builder.submit()


@task(pre=[call(build_core, version='master', remote='origin', branch='master', production=False)])
def start_core(c):
    """Start a local test Core instance."""
    with c.cd('images'):
        print('Starting Core database')
        c.run('sudo docker-compose up -d stellar-core-db', hide='stderr')
        sleep(2)

        # setup core database
        # https://www.stellar.org/developers/stellar-core/software/commands.html
        print('Initializing Core database')
        c.run('sudo docker-compose run stellar-core --newdb --forcescp', hide='both')

        # setup cache history archive
        print('Initializing Core history archive')
        c.run('sudo docker-compose run stellar-core --newhist cache', hide='both')

        # start a local private testnet core
        # https://www.stellar.org/developers/stellar-core/software/testnet.html
        print('Starting Core')
        c.run('sudo docker-compose up -d stellar-core', hide='stderr')


@task(pre=[call(build_go, version='master', remote='origin', branch='master', app='horizon', production=False)])
def start_horizon(c):
    """Start a local test Horizon instance."""
    with c.cd('images'):
        # setup horizon database
        print('Starting Horizon database')
        c.run('sudo docker-compose up -d horizon-db', hide='stderr')
        sleep(2)
        print('Initializing Horizon database')
        c.run('sudo docker-compose run horizon db init', hide='stderr')

        # start horizon
        # envsubst leaves windows carriage return "^M" artifacts when called by docker
        # this fixes it
        print('Starting Horizon')
        c.run('ROOT_ACCOUNT_SEED="{root_account_seed}" sudo -E docker-compose up -d horizon'.format(
            root_account_seed=derive_root_account_seed(PASSPHRASE)), hide='stderr')


@task(pre=[call(build_go, version='master', remote='origin', branch='master', app='friendbot', production=False)])
def start_friendbot(c):
    """Start a local test Friendbot instance."""
    with c.cd('images'):
        # start friendbot
        print('Starting Friendbot')
        c.run('ROOT_ACCOUNT_SEED="{root_account_seed}" sudo -E docker-compose up -d friendbot'.format(
            root_account_seed=derive_root_account_seed(PASSPHRASE)), hide='stderr')


@task(rm_network, start_core, start_horizon, start_friendbot)
def network(_):
    """Initialize a new local test network with single core and horizon instances."""
    base_reserve_0()
    protocol_version_9()
    tx_set_size_500()
    create_whitelist_account()

    print('Root account seed: {}'.format(derive_root_account_seed(PASSPHRASE)))
    print('Network is up')


@task(post=[rm_network])
def test_core(c):
    """Run tests for Core."""
    def test_python(c, filename):
        """Run a single python test file in tests/python."""
        test_dir = 'tests/python'
        filepath = '{}/{}'.format(test_dir, filename)

        print('Restarting network before executing test {}'.format(filepath))
        rm_network(c)
        start_core(c)
        start_horizon(c)
        network(c)

        with c.cd(test_dir):
            print('Executing test {}'.format(filepath))
            c.run('pipenv run python {filename} "{passphrase}" {whitelist_seed}'.format(
                filename=filename,
                passphrase=PASSPHRASE,
                whitelist_seed=WHITELIST_SEED))

    test_python(c, 'test_base_reserve.py')
    test_python(c, 'test_tx_order_by_fee.py')
    test_python(c, 'test_tx_order_by_whitelist.py')
    test_python(c, 'test_tx_priority_for_whitelist_holder.py')
    test_python(c, 'test_whitelist_affected_on_next_ledger.py')

    # XXX obsolete
    # see source file for more information
    # test_python(c, 'test_multiple_cores.py')
