var config = {};

config.pep_port = 10026;

// Set this var to undefined if you don't want the server to listen on HTTPS
// config.https = {
//    enabled: false,
//    cert_file: 'cert/cert.crt',
//    key_file: 'cert/key.key',
//    port: 443
//};

// Our IdM IP
config.account_host = '172.17.0.71';

// Our Keystone Settings. In this case Keystone and Horizon are at the same host
config.keystone_host = '172.17.0.71';
config.keystone_port = 5000;

// The host of the app to protect
config.app_host = '172.17.0.96';
config.app_port = '80';

// The username and password we've used for registering the app (just for testing)
config.username = 'idm';
config.password = 'idm';

// in seconds
config.chache_time = 300;

// if enabled PEP checks permissions with AuthZForce GE.
// only compatible with oauth2 tokens engine
config.azf = {
    enabled: true,
    host: '172.17.0.72',
    port: 8080,
    path: '/authzforce/domains/f7727b3b-0a04-11e5-9a3a-adc96088fc92/pdp'
};

// options: oauth2/keystone
config.tokens_engine = 'oauth2';

config.magic_key = 'daf26216c5434a0a80f392ed9165b3b4';

module.exports = config;
